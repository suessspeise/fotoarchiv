# Archive Conventions

Last updated: 2026-04-10

## Scope

This document defines the conventions used in this photo archive.
It covers: identifiers, folder and file naming, date notation, and
metadata entry. It is the reference point for the scripts in
`scripts/` and the schema in `catalog/schema.sql`.

---

## Folder and File Naming

Original scan folders use the lab's own naming convention and are
**never renamed or moved**. The lab reference (folder name) is the
primary key of the archive — the stable link between the digital
files, the physical negative, and the catalog entry.

Each lab has a distinct naming pattern, which makes lab references
unique across the entire archive without a prefix:

| Lab               | Pattern             | Example        |
|-------------------|---------------------|----------------|
| Jan Kopp, Hamburg | two consecutive int | 144_2208311410 |

> Add labs as they appear. The pattern column is for human
> identification only — no script relies on parsing lab references.

---

### Lab rolls

The lab reference (folder name) is used directly as the primary key.
It is unique, human-readable, and directly maps to the folder on disk
and the catalog files:

```
/masters/144_2208311410/       ← scan folder
catalog/rolls/144_2208311410.toml
catalog/rolls/144_2208311410.md
```

No translation layer or separate accession ID is assigned for lab
rolls.

### Frame references

Where a specific frame needs to be cited (e.g. in person records or
notes), use:

**Format:** `[roll-id]-NN`  
**Example:** `144_2208311410-24`

For now, frame-level IDs will not be stored as explicit database rows.

---

## Dates

Dates are stored as strings in a subset of ISO 8601.

| Known precision | Format       | Example      |
|-----------------|--------------|--------------|
| Full date       | `YYYY-MM-DD` | `1987-06-15` |
| Month only      | `YYYY-MM`    | `1987-06`    |
| Year only       | `YYYY`       | `1987`       |
| Approximate     | append `~`   | `1987-06~`   |
| Unknown         | `-`          | `unknown`    |

- `~` means "believed correct but not verified from a primary source".
- Do not invent a date. An empty field is better than a wrong one.
- `date_shot` refers to when the film was exposed, not when it was
  developed or scanned.

---

## Metadata Files

Each roll has two files in `catalog/rolls/`:

**`[roll-id].toml`** — structured fields, machine-read by `build_db.py`  
**`[roll-id].md`** — free text notes, parsed for frame descriptions

Both files are created automatically by `scripts/ingest.py` as stubs
and filled in by hand using any text editor.

See `docs/metadata_schema.md` for all field definitions.

---

## Frame Descriptions (in `.md` files)

Frame notes follow this format:

```
01: Market stall, Oranienstraße. Peter M. visible on left.
02: —
03: Same location, wider angle.
```

- Frame numbers are zero-padded to match the number of frames on the
  roll (2 digits for 35mm, adjust for other formats).
- `—` means the frame has been reviewed and intentionally left
  undescribed (blank negative, duplicate, etc.).
- A missing line means the frame has not yet been reviewed.
- `—` and missing are distinct states in the database.

---

## Controlled Vocabulary

Canonical values for film stock, camera, and format are defined in
`config/controlled_vocab.toml`. Always use the canonical spelling.
If a value is not in the vocabulary, add it there first, then use it.

---

## Physical Storage

> Document binder/sleeve/box system here once it is settled.
> The `physical_location` field in the schema depends on this.

---

## What This Document Is Not

- It does not define field types or database structure — see
  `catalog/schema.sql`.
- It does not list all metadata fields — see `docs/metadata_schema.md`.
- It does not describe the ingestion workflow — see `docs/workflow.md`.
