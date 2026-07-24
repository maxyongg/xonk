# xonk — roadmap

Live today: profile "You" page, People directory, quadrant rating, per-item
status, item pages. The two taste features (2 & 3) are the app's **main** work
and still being refined — specifics will change.

**Vocabulary**
- **thelist** — a user's logged library.
- **significant similarity** — a still-to-pin-down measure of "these two users
  rated a shared item similarly" (grid closeness and/or genre agreement).

---

## 1. Item pages — done

Read-only pop-up per work (cover, metadata, rating, status, fetched description).

---

## 2. Taste score differential (1-to-1) — main feature, refining

A single **taste match** between two users, over the media both have logged.

**Finding overlap.** Match on exact `extra.srcId` (external TMDB/RAWG/Open Library
id, now captured on new adds), falling back to `(kind, normalized name, year)` for
older items. Only compare items where **both users have a full enjoyment + quality
rating** — skip legacy / quality-only items entirely (no partial-axis matching).

**Score.** Each shared item is two dots on the quadrant (yours, theirs). Take the
straight-line distance between them, mapped to 0–100 (dots touching = 100, opposite
corners ≈ 283 units = 0). Average across all shared items → the overall match.

**Sub-scores** (the "signature" — the interesting part):
- **Enjoyment match** — same map, measuring only the left-right (enjoyment) gap.
- **Quality match** — only the up-down (quality) gap.
- These explain *why*: e.g. enjoyment 90 / quality 40 = "love the same stuff,
  argue about whether it's good."

**Presentation.** Headline match % + the two sub-scores + shared count. Gate the
headline until enough overlap (a 95% match over 3 items is noise). Call-outs:
biggest agreement, biggest split. Keep it a plain average for v1; conviction-
weighting is a possible later toggle.

**Visualization.** One quadrant overlaying both users' dots, a line per shared item
(long line = divergence), "show only divergent" toggle, hover for title. Possible
secondary view: a delta scatter (each item at `(Δenjoyment, Δquality)`, origin =
agreement) to reveal systematic bias.

**Open questions.** Final score scale/presentation; where it lives in the UI
(entry point from the People page).

---

## 3. Find community (many-to-one) — main feature, refining

Find users whose taste matches yours, and qualify groups into communities.
Smaller library drives the %.

- **Step 1 (overlap):** shared-item count ≥ **30% of the smaller user's thelist**.
- **Step 2 (agreement):** ≥ **70% of those overlapping items** are significantly
  similar in rating.
- **Community:** a set of ≥ `n` people where the matching conditions hold across
  the group.

**Open questions.** Is 30% vs the smaller library, your own, or symmetric? Precise
"significantly similar" definition and how 70% is counted. How pairwise matches
aggregate into a group (all pairs? centroid? cluster?). Minimum library sizes to
avoid tiny-list noise. Privacy/consent for surfacing matches.

---

## Backend notes

- Cross-user reads already work (`items` RLS `to authenticated using (true)`; People
  loads all users' items client-side) — the raw material is available today.
- At scale, per-user aggregation + pairwise similarity should move server-side
  (Postgres RPC or edge function) rather than fanning out in the browser.

---

## Lower priority

- **Letterboxd / Goodreads import** — CSV first (full history), RSS auto-sync later.
