# Backend — Supabase

*Read before touching Supabase, SQL, auth, RLS, People/profile loading, edge functions
or the legacy JSON files. Siblings: `data-model.md` (what a row holds),
`ui-flows.md` (what the screens do), `ROADMAP.md` (scaling plans, open questions).
Keep this current — it is how the next session learns any of it.*

Project `nboxbviajfjvjleprrkl`. `SUPA_URL` / `SUPA_KEY` sit in `index.html`; the key is
the browser-safe publishable one, so it belongs in the client. Schema lives in
`supabase-schema.sql` (`profiles`, `items`, RLS, RPCs).

## Auth

Username + password only. Usernames map to synthetic emails (`<user>@users.xonk.app`),
"Confirm email" stays OFF, and there is no password recovery **by design** — no real
address is ever collected, so there is nowhere to send a reset.

## Reads and RLS

- `items` RLS: any authenticated user **reads all rows** (this is what powers the People
  directory and compare); writes are restricted to your own rows.
- `people_directory()` returns one aggregate row per account, so opening People never
  downloads anyone's library. A profile's items load on demand via `loadUserItems` into
  `S.userData`.
- Raw loads page through `selectAll` — PostgREST silently truncates at 1000 rows and
  gives no error, so anything unpaged would look like a smaller library rather than a
  bug. Current row counts and when to revisit any of this: ROADMAP, Backend notes.

## Applying schema changes

**Nothing applies `supabase-schema.sql` automatically.** It is pasted into the dashboard
SQL editor by hand. Land new SQL there *before* pushing JS that calls it — pushing to
`main` deploys instantly, so the reverse order ships a broken app.

## Edge functions

In `supabase/functions/`, deployed via the dashboard (not by any script here).

- `media-search` — proxies TMDB and RAWG; secrets `TMDB_KEY` / `RAWG_KEY`. Books use
  Open Library, which is keyless. Adding fires 3 invocations per debounced keystroke,
  one per keyed source.
- `demo-data` — public, serves the welcome screen's demo account.

## Legacy / dead files

- `films.json`, `tv.json`, `games.json`, `books.json`, `albums.json` — a frozen
  pre-accounts snapshot. Still the demo fallback (`loadLocal`). The one-time
  "Import old JSON lists" button that read them is gone — the migration is done.
- `scripts/` and `.github/workflows/` — unused.
