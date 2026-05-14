-- =============================================================================
-- negative-space catalog schema
-- =============================================================================
-- This file defines the structure of the archive database.
-- It is the machine-readable counterpart to docs/metadata_schema.md.
--
-- To create a fresh database from this file:
--   sqlite3 catalog/catalog.db < catalog/schema.sql
--
-- This file is the source of truth for the database structure.
-- Never modify the database directly — change this file and rebuild.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- Pragmas
-- -----------------------------------------------------------------------------
PRAGMA journal_mode = WAL;
-- WAL (Write-Ahead Logging) is a safer write mode. Without it, a crash
-- mid-write can corrupt the database. With it, writes are staged in a
-- separate file first, then committed. This is why .gitignore excludes
-- the companion .db-shm and .db-wal files.

PRAGMA foreign_keys = ON;
-- By default SQLite does not enforce foreign key relationships even if
-- you define them. This pragma turns enforcement on. Always include it.


-- =============================================================================
-- TABLES
-- =============================================================================
-- A table is a grid of data: columns define what kind of data is stored,
-- rows are individual records. Think of each table as one sheet in a
-- spreadsheet, where the column headers are fixed and typed.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- labs
-- -----------------------------------------------------------------------------
-- Stores one record per lab. This is a lookup table — its only job is to
-- give each lab a stable short name that other tables can reference.
--
-- Why a separate table rather than just typing the lab name into the rolls
-- table? Because if you ever need to correct a lab name, you change it in
-- one place here, and the correction propagates everywhere automatically.
-- This principle is called normalisation.

CREATE TABLE IF NOT EXISTS labs (
    lab_id  TEXT PRIMARY KEY,
    name    TEXT NOT NULL,
    notes   TEXT
);

-- TEXT PRIMARY KEY
--   Every table needs a primary key: a column whose value uniquely identifies
--   each row. No two rows can have the same primary key. Here we use a short
--   text identifier like "lab-a" rather than an auto-incremented number,
--   because it's human-readable and stable.
--
-- NOT NULL
--   This constraint means the column must always have a value. Inserting a
--   row without a `name` will be rejected by the database. Use it for fields
--   that are genuinely required.
--
-- notes TEXT (no NOT NULL)
--   Omitting NOT NULL means the column is nullable — the value can be absent
--   (NULL). NULL in SQL means "no value", which is distinct from an empty
--   string "". We use NULL for optional fields and check for it with
--   IS NULL rather than = NULL.


-- -----------------------------------------------------------------------------
-- rolls
-- -----------------------------------------------------------------------------
-- The central table. One row per roll of film.
-- Most queries will start here or join through here.

CREATE TABLE IF NOT EXISTS rolls (
    roll_id       TEXT PRIMARY KEY,
    lab_id        TEXT REFERENCES labs(lab_id),
    lab_ref       TEXT,
    film_stock    TEXT,
    format        TEXT,
    frame_count   INTEGER,
    development   TEXT,
    date_shot     TEXT,
    date_scanned  TEXT,
    camera        TEXT,
    location      TEXT,
    notes         TEXT
);

-- REFERENCES labs(lab_id)
--   This is a foreign key. It says: the value in this column must exist
--   as a primary key in the labs table. If you try to insert a roll with
--   lab_id = "lab-x" and there is no "lab-x" row in labs, the database
--   will reject it. This enforces referential integrity — you cannot have
--   a roll pointing to a lab that does not exist.
--
--   Foreign keys are the main tool for expressing relationships between
--   tables. The labs table and rolls table are now linked: one lab can
--   appear on many rolls (a one-to-many relationship).
--
-- Why is lab_ref a separate column from lab_id?
--   lab_id is our internal reference to the labs table ("lab-a").
--   lab_ref is the original folder name as assigned by the lab ("2019-034").
--   For lab rolls these look similar but serve different purposes.
--   For self-scanned rolls, lab_id and lab_ref are both NULL.
--
-- date_shot and date_scanned are TEXT, not a DATE type.
--   SQLite has no native date type. Dates are stored as text in the
--   ISO 8601 format defined in conventions.md (e.g. "1987-06~").
--   This lets us store approximate dates with the ~ suffix, which a
--   strict DATE type would reject.
--
-- INTEGER for frame_count
--   SQLite has five storage types: TEXT, INTEGER, REAL, BLOB, NULL.
--   INTEGER stores whole numbers. REAL stores decimals. Frame counts
--   are always whole numbers so INTEGER is correct here.


-- -----------------------------------------------------------------------------
-- frames
-- -----------------------------------------------------------------------------
-- One row per frame (individual photograph) in the archive.
-- Parsed from the .md files by build_db.py.

CREATE TABLE IF NOT EXISTS frames (
    frame_id      TEXT PRIMARY KEY,
    roll_id       TEXT NOT NULL REFERENCES rolls(roll_id) ON DELETE CASCADE,
    frame_number  INTEGER NOT NULL,
    description   TEXT,
    reviewed      INTEGER NOT NULL DEFAULT 0
);

-- frame_id is a composite identifier: roll_id + frame number.
--   e.g. "2019-034-07". It is constructed by build_db.py, not entered
--   manually. It is TEXT rather than an auto-incremented integer so that
--   it remains meaningful and stable even if rows are deleted and rebuilt.
--
-- reviewed INTEGER NOT NULL DEFAULT 0
--   This encodes the three states defined in conventions.md:
--     0 = not yet reviewed (line missing from .md file)
--     1 = reviewed, intentionally undescribed (— in .md file)
--     2 = reviewed and described (line with actual text)
--   SQLite has no boolean type. The convention is INTEGER with 0 = false
--   and 1 = true. Here we extend that to a three-value state using 0/1/2.
--
-- DEFAULT 0
--   If no value is provided for this column on insert, the database
--   automatically uses 0. This means build_db.py only needs to
--   explicitly set reviewed = 1 or 2 for frames that have been seen.
--
-- ON DELETE CASCADE
--   If a roll is deleted, automatically delete its frames too. Without
--   this, deleting a roll would be rejected because frame rows still
--   reference it. CASCADE cleans up the child rows automatically.


-- =============================================================================
-- VIEWS
-- =============================================================================
-- A view is a saved query that behaves like a table. You can SELECT from
-- it as if it were a real table, but it contains no data of its own —
-- it runs the underlying query each time. Views are useful for queries
-- you run often, or to present a simplified shape of the data to tools
-- like Datasette.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- rolls_overview
-- -----------------------------------------------------------------------------
-- A human-friendly summary of each roll: how many frames it has, how many
-- have been reviewed, and how many are described. Useful as a progress view
-- when backfilling metadata.

CREATE VIEW IF NOT EXISTS rolls_overview AS
SELECT
    r.roll_id,
    r.lab_ref,
    r.date_shot,
    r.location,
    r.film_stock,
    r.format,
    r.frame_count,
    COUNT(f.frame_id)                                AS frames_logged,
    SUM(CASE WHEN f.reviewed > 0 THEN 1 ELSE 0 END) AS frames_reviewed,
    SUM(CASE WHEN f.reviewed = 2 THEN 1 ELSE 0 END) AS frames_described
FROM rolls r
LEFT JOIN frames f ON f.roll_id = r.roll_id
GROUP BY r.roll_id;

-- LEFT JOIN
--   A regular JOIN only returns rows where both sides have a match.
--   A LEFT JOIN returns all rows from the left table (rolls) even if
--   there are no matching rows in the right table (frames). This means
--   rolls with no frames yet still appear in the view, with COUNT = 0.
--
-- COUNT(f.frame_id)
--   Counts non-NULL values in the column. For rolls with no frames,
--   f.frame_id is NULL (because of the LEFT JOIN), so COUNT returns 0.
--
-- SUM(CASE WHEN ... THEN 1 ELSE 0 END)
--   SQL has no COUNTIF function. The standard workaround is SUM with a
--   CASE expression that returns 1 when the condition is true and 0
--   otherwise. Summing those gives you the count of matching rows.
--
-- GROUP BY r.roll_id
--   Aggregation functions like COUNT and SUM collapse multiple rows into
--   one. GROUP BY tells the database which column to group on — here we
--   want one output row per roll, so we group by roll_id.


-- =============================================================================
-- INDEXES
-- =============================================================================
-- An index is a separate data structure the database maintains alongside
-- a table to make certain queries faster. Without an index, finding all
-- frames for a given roll means scanning every row in the frames table.
-- With an index on roll_id, the database jumps directly to the right rows.
--
-- Primary keys are always indexed automatically. These are additional
-- indexes for columns you will frequently search or filter on.
-- Add indexes as you discover slow queries — do not over-index upfront.
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_frames_roll_id
    ON frames(roll_id);

CREATE INDEX IF NOT EXISTS idx_rolls_date_shot
    ON rolls(date_shot);

CREATE INDEX IF NOT EXISTS idx_rolls_location
    ON rolls(location);
