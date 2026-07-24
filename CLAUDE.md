# xonk

Media-rating web app (films / games / TV / books) with a two-axis quadrant rating:
x = enjoyment, y = quality ("how well made"), both −100..100. Every rating maps to a
unique colour (hue from angle around the centre per `AXIS_HUES`, pastel→vivid with
distance). Forked from the owner's earlier "List" app (maxyongg.github.io/media).

Live at https://maxyongg.github.io/xonk/ — GitHub Pages serves `main` directly.
**Pushing to main deploys immediately.**

## Architecture

- **Single file**: the entire app is `index.html` (vanilla JS, no build step, no
  framework). Keep it that way unless asked. CSS at top, markup, then one `<script>`.
- **Backend**: Supabase project `nboxbviajfjvjleprrkl` (see `SUPA_URL`/`SUPA_KEY`
  consts in index.html — the key is the browser-safe publishable key).
  - Schema in `supabase-schema.sql` (tables `profiles`, `items` + RLS; run via SQL Editor).
    `profiles` has `display_name` + `tagline` (both optional, editable on the "You" page).
  - Auth is **username + password only**: usernames map to synthetic emails
    (`<user>@users.xonk.app`); "Confirm email" must stay OFF in Supabase auth settings.
    No password recovery by design.
  - `items` RLS: any authenticated user can **read all rows** (powers the People
    directory + cross-user features); writes only your own.
- **Edge functions** (source in `supabase/functions/`, deployed via dashboard):
  - `media-search`: proxies TMDB/RAWG so API keys stay server-side
    (secrets `TMDB_KEY`, `RAWG_KEY`). Books use Open Library directly, keyless.
  - `demo-data`: public (JWT verification OFF), serves the demo account's list +
    profile (secret `DEMO_USERNAME`). Powers the welcome screen's "Demo: Max's Account".
- **Legacy data**: the JSON files (`films.json` etc.) are a frozen pre-accounts
  snapshot — demo fallback + one-time import source. Old 1–10 / 1–5 ratings convert
  via `y = rating/scale*200 − 100`, x = null ("legacy", drawn as a hollow ring).
  `scripts/` + `.github/workflows/` are dead GitHub-sync-era code, not used.

## Features (shipped)

- **Home**: currently-in-progress cards, recently-added rail, cross-category table
  (type-pill filter, sort, search).
- **Stats**: overview + per-category deep dives (rating map, year trend, top genres/creators).
- **Profile / "You"** (`renderProfile`): editorial almanac over the whole catalogue —
  identity (editable name/tagline), stat strip, **rating map** (every rated work as a
  dot, hover/tap tooltip, type filter — view-only, no tap-to-edit), taste signature,
  currently, favourites, milestones, recent activity.
- **People** directory: browse all signed-in users; open a read-only view of anyone's
  almanac. Signed-in only.
- **Item pages** (`openItemPage`): clicking any work opens a **centered modal** (not a
  bottom sheet) with cover, rating, status, description, and all metadata. Description
  is fetched on demand from TMDB/RAWG/Open Library and saved back for your own items.
  Other users' items show an **"Add to my list"** action that starts a prefilled add.
- **Rating picker**: the quad graph shows your **last-rated work as a benchmark** dot +
  caption to calibrate against (`lastRatedItem`; `S.lastRated` set on save, else newest
  by `createdAt`).
- **Per-item status**: Completed / In progress / Did not finish (3-way control). "In
  progress" feeds the Currently section.
- **Secret dev menu**: tap the version stamp → "show only unrated items" table filter.

## Data model

- Item shape in app memory is per-category (creator/year/date field names vary by kind —
  see `COLLECTIONS`). DB rows are flattened; mapping via `rowToItem` / `itemToRow`.
- Rating: `rx` (enjoyment) / `ry` (quality) columns. Legacy items have `rating` only →
  `quadOf` converts to quality-only (x = null).
- `extra` jsonb holds anything without a dedicated column: **`status`**, TV's
  **`released`** (full first-episode air date), and misc leftovers. `in_progress` column
  is kept in sync with `status==='inProgress'`. `createdAt` (from `created_at`) rides on
  the in-memory item for the benchmark; it's excluded from `extra` on save.
- Per-kind field notes: TV uses `released` (a date) instead of season fields; `itemYear`
  derives the display year from it. Games' creator field is `developer`, labelled "Studio".

## Conventions

- Bump the version stamp `<div ... id="verStamp">xonk v(YYYY.MM.DD)(letter)</div>` on every change.
- File uses CRLF line endings (Windows checkout); repo stores LF (git warns; harmless).
- After JS edits, syntax-check the inline script. `node`/`python` are often **not on PATH**
  in this environment — a reliable fallback is the in-app browser: load the page and
  `new Function(<inline script text>)` to catch parse errors, or just load it and check
  the console. `git` runs via the Bash tool (Git Bash), not the PowerShell Run button.
- Testing: the in-app Browser pane only runs JS for the project's own `index.html` over
  `file://`; other files render as static snapshots. To test a variant live, temporarily
  swap it into `index.html` (git-tracked, restore with `git checkout -- index.html`).
- Owner (Max) is signed in on the test browser, so the app loads their real ~850-item
  account — treat writes as real data.
- git history has clean per-feature commits.

## Branches

- `main` — live app
- `pre-accounts-json` — frozen pre-Supabase version (JSON-in-repo storage)
- `row-tint-mockup` — alternative list design: whole row washed in rating colour

## Personal "media" build (separate)

A single-user, no-Supabase fork lives at `../media/` (sibling folder, its own repo →
maxyongg.github.io/media). Same current UI, but data is stored as JSON in the repo with
a localStorage working copy + optional GitHub-token sync, and client-side TMDB/RAWG keys.
Not part of this repo; kept in sync manually when asked.

## Roadmap

Full detail + open questions in **`ROADMAP.md`**. In short:

1. **Item pages** — done.
2. **Taste score differential (1-to-1)** — signature similarity score over two users'
   overlapping libraries; shared media overlaid on one grid. *Main feature, needs refinement.*
3. **Find community (many-to-one)** — match users by library overlap + rating agreement
   (step-1: ≥30% of the smaller library shared; step-2: ≥70% of the overlap significantly
   similar). *Main feature, needs refinement.*
- Earlier/lower priority: Letterboxd + Goodreads CSV import.
