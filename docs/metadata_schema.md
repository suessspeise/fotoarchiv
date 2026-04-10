# Metadata Schema

Last updated: 2026-04-10

This document defines every metadata field in the archive. It is the
reference point for `catalog/schema.sql` and `scripts/build_db.py`.
Fields are grouped by the level they describe: archive, roll, frame,
and person.

For date format and identifier conventions see `docs/conventions.md`.
For canonical field values see `config/controlled_vocab.toml`.

---

## Roll-level fields

Stored in `catalog/rolls/[roll-id].toml`. One record per roll.

### Identity

| Field            | Type    | Required | Example                |
|------------------|---------|----------|------------------------|
| `roll_id`        | string  | yes      | `2019-034`, `SELF-0001`|
| `lab`            | string  | no       | `Lab A`                |
| `lab_ref`        | string  | no       | `2019-034`             |

- `roll_id` is the filename stem and the primary key. For lab rolls,
  it equals `lab_ref`. For self-scanned rolls it is a `SELF-NNNN` ID.
- `lab` and `lab_ref` are redundant for lab rolls but explicit — do
  not omit them. For self-scanned rolls both are left empty.

### Film

| Field            | Type    | Required | Example                |
|------------------|---------|----------|------------------------|
| `film_stock`     | string  | no       | `Kodak Tri-X 400`      |
| `format`         | string  | no       | `35mm`                 |
| `frame_count`    | integer | no       | `36`                   |
| `development`    | string  | no       | `Lab A, standard D-76` |

- `film_stock` and `format` must use canonical values from
  `config/controlled_vocab.toml`.
- `development` is free text — lab name, process, any push/pull notes.

### Capture

| Field            | Type    | Required | Example          |
|------------------|---------|----------|------------------|
| `date_shot`      | string  | no       | `1987-06~`       |
| `date_scanned`   | string  | no       | `2024-03-15`     |
| `camera`         | string  | no       | `Nikon FM2`      |
| `location`       | string  | no       | `Berlin, Kreuzberg` |

- `date_shot` and `date_scanned` follow the date format defined in
  `docs/conventions.md`.
- `location` is free text at whatever precision is known. Prefer
  specific over vague: `Berlin, Kreuzberg` rather than `Berlin` if
  you know it.
- `camera` must use a canonical value from `controlled_vocab.toml`.

### Notes

| Field     | Type   | Required | Example                          |
|-----------|--------|----------|----------------------------------|
| `notes`   | string | no       | `First roll after camera repair` |

- Free text. Roll-level observations that do not belong in any
  structured field. Do not duplicate structured fields here.

---

## Frame-level fields

Stored in `catalog/rolls/[roll-id].md`. One line per described frame.

Frames are not rows in the `.toml` file — they live in the `.md` file
as structured free text, parsed by `build_db.py`.

### Format

```
NN: [description]
```

| Element       | Notes                                               |
|---------------|-----------------------------------------------------|
| Frame number  | Zero-padded to 2 digits. 3 digits for 120 roll film if frame count exceeds 99. |
| Description   | Free text. People referenced by key in brackets.   |
| `—`           | Frame reviewed, intentionally undescribed.          |
| Missing line  | Frame not yet reviewed.                             |

### Example

```
01: Street corner, Oranienstraße. Marktstände visible.
02: —
03: Portrait. [peter-m] and [anna-k] outside Café Übersee.
04: Same group, wider. [peter-m] looking away.
05: —
```

### Location at frame level

If a frame was shot at a different location than the roll default,
note it in the description:

```
07: [Tempelhof, Berlin] Aerial view from the old terminal roof.
```

Location overrides at frame level are free text only — they are not
parsed into a structured field. Use the roll-level `location` field
for the predominant location.

> **Open decision:** if detailed frame-level location tracking becomes
> necessary (e.g. for mapping), introduce a structured frame `.toml`
> format at that point. Do not over-engineer now.

---

## Archive-level fields

Stored in `config/settings.toml` (machine-specific, not committed).
Defined here for documentation purposes only.

| Field               | Example                        | Notes                        |
|---------------------|--------------------------------|------------------------------|
| `masters_path`      | `/Volumes/archive/masters`     | Root of original scan folders|
| `derivatives_path`  | `/Volumes/archive/derivatives` | Root of generated JPEGs      |

---

## What is not stored

The following are deliberately excluded:

- **EXIF data** from scans. Scanner-generated EXIF is meaningless for
  analog originals (it reflects the scanner, not the camera). Relevant
  capture data is entered manually into the structured fields above.
- **File paths.** The path to a scan is derived at runtime from
  `masters_path` + `roll_id`. It is never stored in the database, as
  it is machine-specific.
- **Ratings, picks, colour labels.** These are tool-specific
  organisational states, not archival metadata. If a selection workflow
  is needed in future, introduce a separate `selections/` structure.
