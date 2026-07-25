# xonk

Media-rating web app (films / games / TV / books). Two-axis quadrant rating:
x = enjoyment, y = quality, both −100..100; each rating maps to a unique colour
(hue by angle per `AXIS_HUES`, pastel→vivid with distance). Forked from the owner's
earlier "List" app.

**Live at https://maxyongg.github.io/xonk/ — Pages serves `main`, so pushing to main
deploys immediately.**

## Architecture

- **Single file**: the whole app is `index.html` (vanilla JS, no build, no framework).
  Keep it that way unless asked. CSS at top, markup, then one `<script>`.
- **Backend**: Supabase project `nboxbviajfjvjleprrkl` (`SUPA_URL`/`SUPA_KEY` consts in
  index.html — the key is the browser-safe publishable key). Schema in
  `supabase-schema.sql` (tables `profiles`, `items` + RLS).
  - Auth is **username + password only**: usernames map to synthetic emails
    (`<user>@users.xonk.app`). "Confirm email" must stay OFF; no password recovery by design.
  - `items` RLS: any authed user **reads all rows** (powers People + cross-user features);
    writes only your own.
  - **RPC `people_directory()`** returns one aggregate row per account (works, rated,
    avg rx/ry) so the directory never downloads anyone's library. A profile's items
    load on demand via `loadUserItems` into the `S.userData` cache. Both raw item
    loads page through `selectAll` — PostgREST silently truncates at 1000 rows.
  - **Nothing applies `supabase-schema.sql` automatically** — it's pasted into the
    dashboard SQL editor by hand. So a push whose JS calls new SQL breaks the live
    site until it's run: land the SQL *first*, then push.
- **Compare** (`tm*` functions, after `renderPeople`): `tmPair` finds shared works
  (exact `extra.srcId` → kind+name+year → unambiguous name), `tasteMatch` scores them,
  `tmPanelHTML` builds the modal. Only Max's own items have `srcId` backfilled, so
  cross-account pairing still leans on name+year.
- **Edge functions** (`supabase/functions/`, deployed via dashboard): `media-search`
  proxies TMDB/RAWG (secrets `TMDB_KEY`/`RAWG_KEY`; books use Open Library, keyless);
  `demo-data` is public and serves the demo account for the welcome screen.
- **Legacy/dead**: JSON files (`films.json` etc.) are a frozen pre-accounts snapshot
  (demo fallback + import source); `scripts/` + `.github/workflows/` are unused.

## Data model

- Item shape is per-category (field names vary by kind — see `COLLECTIONS`). DB rows are
  flattened; map via `rowToItem` / `itemToRow`.
- Rating: `rx` (enjoyment) / `ry` (quality) columns. Legacy items have `rating` only →
  `quadOf` converts to quality-only (x = null, drawn as a hollow ring).
- `extra` jsonb holds anything without a dedicated column: `status`, TV's `released`
  (first-episode air date), misc leftovers. `in_progress` column stays in sync with
  `status==='inProgress'`. `createdAt` rides on the in-memory item but is excluded from
  `extra` on save.
- Per-kind notes: TV uses `released` (a date) not season fields; Games' creator field is
  `developer`, labelled "Studio".

## Conventions

- **Owner (Max) is signed in on the test browser → the app loads their real ~900-item
  account. Treat all writes as real data.**
- Bump the version stamp (`id="verStamp">xonk v(YYYY.MM.DD)(letter)`) on every change.
- After JS edits, syntax-check the inline script. `node`/`python` are often **not on PATH**;
  fallback is the in-app browser — load the page and `new Function(<script text>)` to catch
  parse errors, or check the console. `git` runs via the Bash tool (Git Bash).
- Testing: the Browser pane only runs JS for this project's `index.html` over `file://`.
  To test a variant live, swap it into `index.html` (restore with `git checkout -- index.html`).
- File is CRLF (Windows checkout); repo stores LF (git warns; harmless).

## Unsettled

- **Lean penalty (`TM_LEAN_K`, `tmLeanPenalty`) is provisional — do not treat as
  settled.** Compare docks a pair's score when the two ratings sit on opposite
  sides of the `y=±x` diagonals (one enjoyed it more than they rate it, the other
  the reverse), scaled by `min(|lean|)`. `k=0.2` is a guess and nothing has been
  validated against real data yet. `tasteMatch` returns `overallRaw` + `crossLean`
  for exactly that assessment. See ROADMAP §2.

## Also

- **Roadmap / open questions**: see `ROADMAP.md` (main upcoming work:
  find-community many-to-one matching; 1-to-1 compare has shipped).
- **Branches**: `main` (live), `pre-accounts-json` (frozen pre-Supabase JSON storage),
  `row-tint-mockup` (row washed in rating colour).
- **Personal build**: a single-user, no-Supabase fork lives at `../media/` (own repo →
  maxyongg.github.io/media); kept in sync manually when asked.
