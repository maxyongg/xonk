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
  - Auth is **username + password only**: usernames map to synthetic emails
    (`<user>@users.xonk.app`); "Confirm email" must stay OFF in Supabase auth settings.
    No password recovery by design.
  - `items` RLS: any authenticated user can read all rows (for future cross-user
    comparison); writes only your own.
- **Edge functions** (source in `supabase/functions/`, deployed via dashboard):
  - `media-search`: proxies TMDB/RAWG so API keys stay server-side
    (secrets `TMDB_KEY`, `RAWG_KEY`). Books use Open Library directly, keyless.
  - `demo-data`: public (JWT verification OFF), serves the demo account's list
    (secret `DEMO_USERNAME`). Powers the welcome screen's "Demo: Max's Account".
- **Legacy data**: the JSON files (`films.json` etc.) are a frozen pre-accounts
  snapshot — kept as demo fallback and import source. Old 1–10 / 1–5 ratings convert
  via `y = rating/scale*200 − 100`, x = null ("legacy", drawn as hollow ring).
  `scripts/` + `.github/workflows/` are dead GitHub-sync-era code, not used.

## Conventions

- Bump the version stamp `<div class="version">xonk v(date)(letter)</div>` on every change.
- File uses CRLF line endings (Windows checkout); repo stores LF.
- Item shape in app memory is per-category (creator/year/date field names vary by kind —
  see `COLLECTIONS`); DB rows are flattened (creator/year/date_logged + `extra` jsonb).
  Mapping via `rowToItem` / `itemToRow`.
- After JS edits, syntax-check the inline script (extract between `<script>` and the
  LAST `</script>`, then `node --check`).
- Test locally with VS Code Live Server; git history has clean per-feature commits.

## Branches

- `main` — live app
- `pre-accounts-json` — frozen pre-Supabase version (JSON-in-repo storage)
- `row-tint-mockup` — alternative list design: whole row washed in rating colour

## Roadmap (owner's priorities)

1. Cross-user comparison (deferred until there are more users; schema already supports it)
2. Letterboxd import — CSV upload first (full history), RSS auto-sync later
3. Goodreads import — same approach
4. User profile pages (natural home for 1–3)
