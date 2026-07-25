# xonk — roadmap

Live: profile "You" page, People directory, quadrant rating, per-item status,
item pages (1), 1-to-1 compare (2). Find-community (3) is the remaining **main**
feature, still being refined. Section numbers are referenced from CLAUDE.md and
code comments — don't renumber.

**thelist** — a user's logged library. **significant similarity** — still to pin
down: "these two rated a shared item similarly" (grid closeness and/or genre).

---

## 2. Taste score differential (1-to-1) — shipped, one part unsettled

**Compare** on another user's profile (never your own) opens a modal: headline
match % (sub-scores on hover), verdict, overlay plot with a line per shared work,
"only divergent" toggle, closest-agreement / biggest-split call-outs. Under
`TM_MIN` shared works it says so instead of pretending the number means anything.

`tmPair` finds overlap in three tiers, each item pairing once: exact `extra.srcId`,
then `(kind, name, year)`, then name alone — the last only when a year is missing
on one side and the name is unambiguous, so a remake can't match its original.
Only items **both users rated on both axes** count. `tasteMatch` maps the distance
between the two dots to 0–100 (touching = 100, opposite corners = 200√2 = 0) and
averages; the sub-scores run the same map one axis at a time, which is what
explains *why* — enjoyment 90 / quality 40 = "same taste, different verdict".

### ⚠ Lean penalty — provisional, needs assessment

The `y=±x` diagonals halve each quadrant into feelings-led (`|x|>|y|`) and
craft-led (`|y|>|x|`). When two ratings land on opposite sides, `tmLeanPenalty`
docks the pair by `k · min(|lean|)`, `lean = |x|−|y|` — the `min` fades the
penalty to nothing near the diagonal, so there's no cliff at the boundary.
Example: `(+54,+5)` vs `(+12,+32)` → 82% raw, 78% penalised.

- `TM_LEAN_K = 0.2` is a guess, unvalidated against real data.
- Measure the cross-lean rate first (`tasteMatch` returns `overallRaw` +
  `crossLean`): if it fires on nearly every pair it's noise, if rarely it's cosmetic.
- It drags *every* pairing down, so "a good score" has shifted from pre-penalty numbers.
- **Rejected**: hard-gating (dropping cross-lean pairs) — it deletes precisely the
  disagreements, so the average *rises* the more two people differ.
- Cheaper alternative: leave the score alone and surface it as a call-out
  ("you relate differently to N works").

**Later.** Conviction weighting; a delta scatter (`(Δenjoyment, Δquality)`, origin =
agreement) to expose systematic bias; match % on the People cards.

---

## 3. Find community (many-to-one) — main feature, refining

Find users whose taste matches yours, then qualify groups into communities.
Smaller library drives the %.

- **Overlap:** shared items ≥ **30% of the smaller user's thelist**.
- **Agreement:** ≥ **70% of those** are significantly similar.
- **Community:** ≥ `n` people where the conditions hold across the group.

**Open questions.** Is 30% vs the smaller library, your own, or symmetric? The
"significantly similar" definition and how 70% is counted. How pairwise matches
aggregate into a group (all pairs? centroid? cluster?). Minimum library size.
Privacy/consent for surfacing matches.

---

## Backend notes

**Today (25 Jul 2026):** 921 `items` rows across all accounts — the 1000-row cap
was never truncating, so `selectAll`'s paging is preventative. The directory is a
Postgres aggregate (`people_directory()`, live) and a library loads only when you
open that person, so the old (accounts × items) download per People visit is gone.
Revisit when total rows pass ~10,000 or People takes over ~2s.

**Next, when needed.** Compare still pulls both libraries client-side. The step
after this is an RPC that does the *pairing* in SQL and returns only shared rows,
leaving scoring in JS — same payload win, no formula duplicated while the penalty
is unsettled. Full server-side scoring is only forced by §3, which ranks you
against every account at once; settle the penalty before freezing it into SQL.
The hard part is `tmPair`: the name-only tier needs a uniqueness count, and "each
item pairs once" is a greedy assignment (`DISTINCT ON` / `row_number()`), not a
plain join.

---

## Lower priority

- **Letterboxd / Goodreads import** — CSV first (full history), RSS auto-sync later.
