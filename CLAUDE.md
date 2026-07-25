# xonk

Media-rating web app (films / games / TV / books). Two-axis rating: x = enjoyment,
y = quality, both −100..100; each rating maps to a unique colour (hue by angle per
`AXIS_HUES`, pastel→vivid with distance). Forked from the owner's earlier "List" app.

**Live at https://maxyongg.github.io/xonk/ — Pages serves `main`, so pushing to main
deploys immediately.**

## Architecture

- **Single file**: the whole app is `index.html` (vanilla JS, no build, no framework).
  Keep it that way unless asked. CSS at top, markup, then one `<script>`.
- **Backend**: Supabase project `nboxbviajfjvjleprrkl` (`SUPA_URL`/`SUPA_KEY` in
  index.html — the key is the browser-safe publishable one). Schema in
  `supabase-schema.sql` (`profiles`, `items`, RLS, RPCs).
  - Auth is **username + password only** — usernames map to synthetic emails
    (`<user>@users.xonk.app`). "Confirm email" stays OFF; no password recovery by design.
  - `items` RLS: any authed user **reads all rows** (powers People + compare); writes own only.
  - `people_directory()` returns one aggregate row per account, so the directory never
    downloads anyone's library; a profile's items load on demand via `loadUserItems`
    into `S.userData`. Raw item loads page through `selectAll` — PostgREST silently
    truncates at 1000 rows.
  - **Nothing applies `supabase-schema.sql` automatically** — it's pasted into the
    dashboard SQL editor by hand, so land new SQL *before* pushing JS that calls it.
- **Compare** (`tm*` functions): `tmPair` pairs shared works, `tasteMatch` scores,
  `tmPanelHTML` renders the modal. Only Max's items have `extra.srcId` backfilled, so
  cross-account pairing mostly falls back to name+year. Details in ROADMAP §2.
- **Edge functions** (`supabase/functions/`, deployed via dashboard): `media-search`
  proxies TMDB/RAWG (secrets `TMDB_KEY`/`RAWG_KEY`; books use Open Library, keyless);
  `demo-data` is public and serves the welcome screen's demo account.
- **Legacy/dead**: `films.json` etc. are a frozen pre-accounts snapshot (demo fallback +
  import source); `scripts/` + `.github/workflows/` are unused.

## Data model

- Item shape is per-category (see `COLLECTIONS`); DB rows are flat — map via
  `rowToItem` / `itemToRow`.
- `rx` (enjoyment) / `ry` (quality). Legacy items have `rating` only → `quadOf` makes
  them quality-only (x = null, hollow ring).
- `extra` jsonb holds what has no column: `status`, TV's `released` (first-episode air
  date), `srcId`, leftovers. `in_progress` mirrors `status==='inProgress'`. `createdAt`
  rides on the in-memory item but is stripped from `extra` on save.
- TV uses `released` (a date), not season fields; Games' creator field is `developer`,
  labelled "Studio".

## Conventions

- **Max is signed in on the test browser → the app loads his real ~900-item account.
  Treat all writes as real data.**
- Bump the version stamp (`id="verStamp">xonk v(YYYY.MM.DD)(letter)`) on every change.
- After JS edits, syntax-check the inline script. `node`/`python` are often **not on
  PATH**; fallback is the in-app browser — `new Function(<script text>)` to catch parse
  errors. `git` runs via the Bash tool (Git Bash).
- The Browser pane only runs JS for this project's `index.html` over `file://`. To test
  a variant, swap it into `index.html` (restore with `git checkout -- index.html`).
- File is CRLF (Windows checkout); repo stores LF (git warns; harmless).

## Unsettled

**Lean penalty (`TM_LEAN_K = 0.2`, `tmLeanPenalty`) is provisional** — compare docks a
pair whose two ratings sit on opposite sides of the `y=±x` diagonals. `k` is a guess,
unvalidated; `tasteMatch` returns `overallRaw` + `crossLean` for the assessment. ROADMAP §2.

## Also

- **Roadmap / open questions**: `ROADMAP.md` (next main feature: find-community).
- **Branches**: `main` (live), `pre-accounts-json` (frozen JSON storage), `row-tint-mockup`.
- **Personal build**: single-user, no-Supabase fork at `../media/` (own repo →
  maxyongg.github.io/media); synced manually when asked.
