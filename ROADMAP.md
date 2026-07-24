# xonk — roadmap

The live app (profile "You" page, People directory, quadrant rating, per-item
status) is shipped. What follows is the forward roadmap. Item pages are the
next concrete build; the taste-comparison and community features are the
app's **main** features and are still at the brainstorming/definition stage —
expect the specifics below to change as they get refined.

---

## 1. Item pages

Each piece of media gets its own **pop-up page** when clicked, showing a basic
description plus all its other metadata.

- Opens as a pop-up/overlay (not a full route) from anywhere an item is
  clickable today (home table, rails, rating-map dots, profile cards, activity).
- Content: cover, title, creator, year/date, genre, the quadrant rating
  (enjoyment × quality) and status, the fetched description, and every other
  stored field for that kind.
- This is distinct from the current edit sheet — it's a **read view** of the
  work; editing stays a separate action.

---

## The two main features (2 & 3 below)

These are the marquee features of the app and will need plenty of refinement.
Both are about **taste**: how alike two people's ratings are, and finding
people whose taste matches yours.

Shared vocabulary:
- **thelist** — a user's consumed library (everything they've logged).
- **significant similarity** — a still-to-be-pinned-down measure of "these two
  users rated this shared item similarly." Candidate signals: closeness of the
  two ratings on the enjoyment × quality grid, and/or agreement within a genre.

---

## 2. Taste score differential (1-to-1 comparison)

Generate a **signature taste-score differential** between two users — the
core comparison feature.

- **Question it answers:** for the media both users have consumed, how similar
  are their ratings?
- **Scope:** computed over the **overlap** of the two users' `thelist`s
  (media both have consumed).
- **Visualization idea:** overlay the shared consumed media on a single grid
  (the enjoyment × quality quadrant) so the two users' ratings can be compared
  at a glance — e.g. paired dots / connecting lines showing where tastes
  converge and diverge.
- **Output:** a single differential/similarity score (the "signature"), plus
  the per-item breakdown behind it.

**Open questions (to refine):**
- Exact formula for the differential — distance on the grid? weighted by how
  extreme each rating is? per-genre weighting?
- How to handle legacy (quality-only) ratings, and items only one user has rated.
- What the score's range/scale is and how it's presented.

---

## 3. Find community (many-to-one matching)

Goal: **find other users whose taste profile is similar to yours**, and
qualify groups into communities.

Matching model (as currently defined — the smaller library drives the %):

- **Step 1 match (library overlap).** Two users step-1 match when the count of
  media they've both consumed is at least **30% of the smaller user's `thelist`**.
  - *Example:* user 1 has 100 consumed items, user 2 has 10. If user 1 has
    consumed **3 of the 10** items in user 2's list, that's 30% of the smaller
    library → step 1 match.
- **Step 2 match (rating agreement).** A step-1 match becomes a step-2 match
  when at least **70% of the step-1 overlapping items** are **significantly
  similar** in how the two users rated them (see "significant similarity" —
  possibly identified via genre).
- **Community qualification.** You qualify to form a community of at least
  `n` people when the matching conditions hold across that set — roughly:
  30% consumed-library overlap **and** 70% of the matched library falling
  within significant-similarity datapoints, sustained across the `n` members.

**Open questions (to refine):**
- Is the 30% threshold measured against the smaller library (per the example),
  your own library, or symmetric both ways?
- Precise definition of "significantly similar" (grid distance threshold? genre
  agreement? both?) and how the 70% is counted.
- How community qualification aggregates pairwise matches into a group of `n`
  (every pair must match? match to a centroid/seed member? cluster?).
- Minimum library sizes to avoid tiny-list noise (3-of-10 is fragile at small
  numbers).
- Privacy/consent model for surfacing matches and forming communities.

---

## Backend notes

- The schema already supports cross-user reads: `items` is readable by any
  authenticated user (RLS `to authenticated using (true)`), and the People
  directory already loads all users' items client-side — the raw material for
  overlap/similarity math is available today.
- At scale, the per-user aggregation and pairwise similarity should likely move
  server-side (Postgres RPC or an edge function) rather than fanning out in the
  browser.

---

## Earlier roadmap items (still open, lower priority)

- **Letterboxd import** — CSV upload first (full history), RSS auto-sync later.
- **Goodreads import** — same approach.
