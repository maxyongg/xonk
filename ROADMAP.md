# xonk — roadmap

Live today: profile "You" page, People directory, quadrant rating, per-item
status, item pages, 1-to-1 compare. Find-community (3) is the remaining **main**
feature and still being refined — specifics will change.

**Vocabulary**
- **thelist** — a user's logged library.
- **significant similarity** — a still-to-pin-down measure of "these two users
  rated a shared item similarly" (grid closeness and/or genre agreement).

---

## 1. Item pages — done

Read-only pop-up per work (cover, metadata, rating, status, fetched description).

---

## 2. Taste score differential (1-to-1) — done

A single **taste match** between two users, over the media both have logged.
Shipped as a **Compare** button on another user's profile (never your own),
opening a centered modal: headline match %, enjoyment + quality sub-scores,
verdict sentence, overlay plot with a line per shared work, "only divergent"
toggle, and closest-agreement / biggest-split call-outs. Below `TM_MIN` shared
works the modal says so rather than pretending the number means anything.

**Finding overlap** (`tmPair`) — three tiers, each of their items pairing once:
exact `extra.srcId`, then `(kind, normalized name, year)`, then name alone — the
last only when a year is missing on one side and the name is unambiguous, so a
remake can't match its original. Only items **both users rated on both axes**
take part; legacy / quality-only items have no enjoyment value to compare.

**Score** (`tasteMatch`) — each shared item is two dots on the quadrant. Take the
straight-line distance between them, mapped to 0–100 (dots touching = 100,
opposite corners = 200√2 ≈ 283 units = 0). Average across all shared items → the
overall match. The two sub-scores run the same map on one axis at a time, which
is what explains *why*: enjoyment 90 / quality 40 = "love the same stuff, argue
about whether it's good." Plain average, no conviction-weighting.

**Later.** Conviction-weighting toggle (strong opinions counting for more); a
delta scatter (each item at `(Δenjoyment, Δquality)`, origin = agreement) as a
secondary view to reveal systematic bias; a match % on the People cards.

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
