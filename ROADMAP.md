# xonk — roadmap

Live: profile "You" page, People directory, quadrant rating, per-item status,
item pages (1), 1-to-1 compare (2). Find-community (3) is the remaining **main**
feature and still being refined — specifics will change. Section numbers are
referenced from CLAUDE.md and code comments, so don't renumber.

**thelist** — a user's logged library. **significant similarity** — still to pin
down: "these two rated a shared item similarly" (grid closeness and/or genre).

---

## 2. Taste score differential (1-to-1) — shipped, one part unsettled

A **Compare** button on another user's profile (never your own) opens a modal:
headline match %, enjoyment + quality sub-scores, verdict sentence, overlay plot
with a line per shared work, "only divergent" toggle, closest-agreement /
biggest-split call-outs. Under `TM_MIN` shared works it says so rather than
pretending the number means anything.

**Finding overlap** (`tmPair`) — three tiers, each of their items pairing once:
exact `extra.srcId`, then `(kind, normalized name, year)`, then name alone — the
last only when a year is missing on one side and the name is unambiguous, so a
remake can't match its original. Only items **both users rated on both axes**
take part; legacy / quality-only items have no enjoyment value to compare.

**Score** (`tasteMatch`) — each shared item is two dots on the quadrant. Take the
straight-line distance between them, mapped to 0–100 (touching = 100, opposite
corners = 200√2 ≈ 283 units = 0). Average across shared items. The two sub-scores
run the same map on one axis at a time, which is what explains *why*: enjoyment
90 / quality 40 = "love the same stuff, argue about whether it's good."

### ⚠ Lean penalty — provisional, needs assessment

Distance alone can't see a difference in *kind*. The `y=±x` diagonals halve each
quadrant into feelings-led (`|x|>|y|`) and craft-led (`|y|>|x|`). When two ratings
land on opposite sides — one enjoyed it more than they rate it, the other the
reverse — `tmLeanPenalty` docks the pair by `k · min(|lean|)`, `lean = |x|−|y|`.
The `min` makes the penalty fade to nothing near the diagonal, where the lean is
rating noise, so there's no cliff at the boundary and a lean of exactly 0 costs
nothing. Worked example: `(+54,+5)` vs `(+12,+32)` → 82% raw, 78% penalised.

**Unsettled, in order:**
- `TM_LEAN_K = 0.2` is a guess. Nothing validated against real data.
- Measure the cross-lean rate across the real accounts first. If it fires on
  nearly every pair the signal is noise; if it's rare the penalty is cosmetic.
  `tasteMatch` returns `overallRaw` and `crossLean` for this.
- The penalty drags *every* pairing down, so "what counts as a good score" has
  shifted from the numbers shown before it landed.
- Considered and **rejected**: hard-gating (dropping cross-lean items from the
  set). It deletes precisely the disagreements, so the average rises the more
  two people differ — and it would drop near-identical pairs like `(50,49)` vs
  `(49,50)` that straddle the boundary.
- Cheaper alternative if the penalty doesn't earn its place: keep the score
  untouched and surface the same insight as a call-out — "you relate differently
  to N works."

**Later.** Conviction-weighting toggle (strong opinions counting for more); a
delta scatter (each item at `(Δenjoyment, Δquality)`, origin = agreement) to
reveal systematic bias; a match % on the People cards.

---

## 3. Find community (many-to-one) — main feature, refining

Find users whose taste matches yours, then qualify groups into communities.
Smaller library drives the %.

- **Overlap:** shared-item count ≥ **30% of the smaller user's thelist**.
- **Agreement:** ≥ **70% of those overlapping items** are significantly similar.
- **Community:** ≥ `n` people where the conditions hold across the group.

**Open questions.** Is 30% vs the smaller library, your own, or symmetric?
Precise "significantly similar" definition and how 70% is counted. How pairwise
matches aggregate into a group (all pairs? centroid? cluster?). Minimum library
size to avoid tiny-list noise. Privacy/consent for surfacing matches.

---

## Backend notes

Cross-user reads already work (`items` RLS `to authenticated using (true)`), so
the raw material is there. Both item loads page via `selectAll` — PostgREST caps
a plain select at the project's "Max rows" (1000) and doesn't say when it
truncates. `loadPeople` skips the `summary` column since nothing there renders
it.

The directory is a Postgres aggregate (`people_directory()`), and a library is
fetched only when you open that person — so the old (accounts × items) download
on every People visit is gone.

**Next, when needed.** Compare still needs both libraries client-side. The step
after this is an RPC that does the *pairing* in SQL and returns only the shared
rows, leaving the scoring in JS — same payload win, no formula duplicated while
the lean penalty is still unsettled. Full server-side scoring is only forced by
§3 (find-community), which has to rank you against every account at once; that's
the point where the formula gets frozen into SQL, so settle the penalty first.
The hard part is `tmPair`, not the arithmetic: the name-only tier needs a
uniqueness count, and "each item pairs at most once" is a greedy assignment
(`DISTINCT ON` / `row_number()`), not a plain join.

---

## Lower priority

- **Letterboxd / Goodreads import** — CSV first (full history), RSS auto-sync later.
