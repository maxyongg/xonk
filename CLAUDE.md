# xonk

Media-rating web app (films / games / TV / books). Two-axis rating: x = enjoyment,
y = quality, both −100..100; each rating maps to a unique colour. Forked from the
owner's earlier "List" app.

**Live at https://maxyongg.github.io/xonk/ — Pages serves `main`, so pushing to main
deploys immediately.**

## Rules

- **Single file**: the whole app is `index.html` (vanilla JS, no build, no framework).
  CSS at top, markup, then one `<script>`. Keep it that way unless asked.
- **Max is signed in on the test browser → the app loads his real ~900-item account.
  Treat all writes as real data.**
- Bump the version stamp (`id="verStamp">xonk v(YYYY.MM.DD)(letter)`) on every change.
- **Land new SQL in the Supabase dashboard *before* pushing JS that calls it** — nothing
  applies `supabase-schema.sql` automatically and `main` deploys instantly.
- After JS edits, syntax-check the inline script. `node`/`python` are often **not on
  PATH**; fallback is the in-app browser — `new Function(<script text>)` catches parse
  errors. It only runs JS for this project's `index.html` over `file://`; to test a
  variant, swap it into `index.html` (restore with `git checkout -- index.html`).
  `git` runs via the Bash tool (Git Bash).
- File is CRLF (Windows checkout); repo stores LF (git warns; harmless).

## Reference docs — open the ones your task hits, before you edit

These are **not** auto-loaded; nothing pulls them in unless you Read them. They record
decisions whose reasons aren't visible in the code, so a change made without the
relevant one tends to re-break something that was already fixed.

| You are about to touch | Read first |
| --- | --- |
| item fields, ratings, `extra`, re-logs, `rowToItem`/`itemToRow`, anything about whether two entries are the same work | `docs/data-model.md` |
| the add/search flow, duplicate warning, re-log or log deletion, Currently cards, the compare modal's wiring, whether a dialog is a bottom sheet or a centred modal | `docs/ui-flows.md` |
| Supabase, SQL, auth, RLS, People/profile loading, edge functions, the JSON files | `docs/backend.md` |
| scoring formulas, why a feature is shaped the way it is, what's next, anything numbered §1–§3 | `ROADMAP.md` |

Two habits that keep this working:

- **When you change behaviour one of these describes, update it in the same commit.** A
  doc that lies is worse than no doc, and the next session can't tell the difference.
- **When you learn something the hard way** — a footgun, a constraint, why an obvious
  approach fails — write it into the matching doc rather than only the chat reply.
  Add a new `docs/*.md` and a row above if it fits none of them; keep CLAUDE.md itself
  to things that apply to *every* session.

Current state: next up is the stats page + timeline; next main feature is
find-community (ROADMAP §3, blocked on beta users). Don't renumber ROADMAP sections —
code comments cite them.

## Also worth knowing

- **Branches**: `main` (live), `pre-accounts-json` (frozen JSON storage), `row-tint-mockup`.
- **Personal build**: single-user, no-Supabase fork at `../media/` (own repo →
  maxyongg.github.io/media); synced manually when asked.
