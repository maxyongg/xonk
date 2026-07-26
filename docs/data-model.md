# Data model

*Read before touching item fields, ratings, `extra`, re-logs, `rowToItem`/`itemToRow`, or
anything that decides whether two entries are the same work. Siblings: `backend.md`
(where rows live), `ui-flows.md` (the screens over this), `ROADMAP.md` (open questions).
Keep this current — it is how the next session learns any of it.*

Item shape is per-category — see `COLLECTIONS` in `index.html`. DB rows are flat; map
between the two with `rowToItem` / `itemToRow`.

## Ratings

`rx` = enjoyment, `ry` = quality, both −100..100. Each rating maps to a unique colour:
hue by angle per `AXIS_HUES`, pastel→vivid with distance from the origin (`quadColor`).

Legacy items carry `rating` only. `quadOf` turns those into quality-only points
(x = null), drawn as a hollow ring.

## A row is a work, not a sitting

Re-consuming something appends to `extra.logs` (dates only) and moves `date_logged` to
the latest date. **The rating stays single** — a work has one rating no matter how many
times you log it; the count is just `logs.length` ("watched 5 times").

Rows that were never re-logged have no `logs` key at all — `logsOf` derives `[date_logged]`
for them, so there was nothing to migrate when this shipped. Deleting logs back down to
one drops the array again (`saveRelog`, `removeLog`).

Helpers: `logsOf(k, item)`, `logCount(k, item)`, `dateFieldOf(k)`, and the wording tables
`LOG_VERB` / `REPEAT_NOUN` / `ING` (watched/re-watch/watching per kind).

## `extra` jsonb

Holds everything without a dedicated column: `status`, `logs`, TV's `released`
(first-episode air date), `srcId`, plus leftovers. Notes:

- `in_progress` mirrors `status === 'inProgress'`.
- `createdAt` rides along on the in-memory item but is stripped from `extra` on save.
- `itemToRow` builds `extra` from every non-column, non-null key — so setting a key to
  `null` is how you *remove* it.

## Per-category quirks

- TV uses `released` (a date), not season fields.
- Games' creator field is `developer`, labelled "Studio" in the UI.

## "Same work?" — the identity rule

`sameWork()` is the single definition, shared by the duplicate check and compare's
`tmPair`. Two tiers:

1. exact `extra.srcId` (with kind)
2. `kind + normName(name) + year`

`workKeys` builds the key pair, `itemKeys` does it for a stored item, `findExisting`
scans a category for a match. **Don't give one caller a tier the other doesn't have** —
a tier that is a tolerable silent miss in compare can be an intolerable false "you
already logged this" when adding. That asymmetry is why the old name-only third tier
was dropped. See ROADMAP §2.
