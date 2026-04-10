# fotoarchiv
scripts and metadata to manage my photo archive

This is work in progress.

---

## TODO
### aiming at this repo structure

```
fotoarchiv/
│
├── README.md                        ← entry point: what this is, how to use it
├── .gitignore
│
├── catalog/
│   ├── rolls/                       ← one pair of files per roll (your primary data entry)
│   │   ├── 0001.toml                ← structured fields: date, location, film, camera
│   │   ├── 0001.md                  ← free text: frame notes, people, stories
│   │   ├── 0002.toml
│   │   ├── 0002.md
│   │   └── ...
│   ├── schema.sql                   ← authoritative DB definition, human-readable
│   ├── catalog.db                   ← derived artifact, built by build_db.py
│   └── exports/                     ← CSV snapshots committed to git for diffability
│       ├── rolls.csv
│       ├── frames.csv
│
├── scripts/
│   ├── ingest.py                    ← intake new scan folder → create .toml + .md stubs
│   ├── build_db.py                  ← parse all .toml/.md → populate catalog.db
│   ├── verify_checksums.py          ← re-hash masters, compare to DB, report anomalies
│   ├── generate_derivatives.py      ← create web-res JPEGs and thumbnails from masters via pillow
│   ├── export_csv.py                ← dump DB tables → exports/
│   └── serve.sh                     ← datasette catalog.db (one-liner search UI)
│
├── config/
│   ├── settings.toml                ← local paths to masters/derivatives (gitignored)
│   ├── settings.toml.example        ← committed template with placeholder paths
│   └── controlled_vocab.toml        ← canonical spellings: film stocks, cameras, formats
│
└── docs/
    ├── conventions.md               ← ID scheme, date format, uncertainty notation
    ├── metadata_schema.md           ← every field defined, with examples
    ├── workflow.md                  ← step-by-step: how to ingest a new roll
    └── physical_storage.md          ← how boxes/binders/sleeves are organised
```


### Files to create

#### Phase 1 — Decisions crystallised as documents
*Nothing else can be built until these are settled.*

**1. `docs/conventions.md`** :check_mark:

**2. `config/controlled_vocab.toml`**
List every film stock, camera, and format. Canonical spellings only. This doesn't need to be complete.

**3. `docs/metadata_schema.md`**
Define every field: name, type, required/optional, example value, which fields live in `.toml` (structured) vs `.md` (free text). This document is what `schema.sql` and `build_db.py` will both be written against.

---

#### Schema and a first roll

**4. `catalog/schema.sql`**
Translate `metadata_schema.md` into SQL tables. Write it by hand.

**5. `catalog/rolls/*.toml` + `*.md`** (manually)
Pick one existing roll and fill it in completely by hand using a text editor. 

---

#### Phase 3 — Scripts, simplest first

**6. `scripts/build_db.py`**
Reads all `.toml` and `.md` files in `catalog/rolls/`, creates `catalog.db`. Start here because it gives you immediate payoff: a searchable database from your hand-entered data.

**7. `scripts/serve.sh`**
One line: `datasette catalog/catalog.db`. Instant search UI over everything you've entered.

**8. `scripts/ingest.py`**
Automates what you did manually in step 5: given a lab folder, creates stub `.toml` and `.md` files with the lab ref pre-filled, checksums the files, logs them. Now new rolls flow in properly. It might make more sense to do this over all folders and fill in missing `.toml/.md` stubs.

**9. `scripts/verify_checksums.py`** and **`scripts/export_csv.py`**
Integrity and backup tooling. Less urgent but important before the archive grows large.

**10. `scripts/assess_compeleteness.py` give an overview of how many rolls are missing metadata.
---

### (Open) Decisions

**`catalog.db` in git or gitignored**
should be rebuild from the tomls. **gitignoring the DB and committing CSVs** is the cleaner approach.

