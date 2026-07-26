# UI flows

*Read before touching the add/search flow, the duplicate warning, re-logging or log
deletion, Currently cards, the compare modal's wiring, or any dialog's sheet-vs-modal
presentation. Siblings: `data-model.md`
(what these flows write), `backend.md` (where it goes), `ROADMAP.md` (scoring, what's
next). Keep this current — it is how the next session learns any of it.*

## Adding

One search hits all four sources at once — `searchAllSuggestions` fans out over
`SEARCH_KINDS`, takes the top few per source and re-ranks the merged list by
`titleCloseness` (exact > prefix > substring > word overlap, minus a small penalty for
the source's own ordering).

- **The kind comes from the result you pick**, and picking is what sets `S.tab`.
  Suggestion rows are keyed by a composite `data-sid="${kind}:${id}"` because ids only
  collide across sources.
- The kind picker (`#typePick`) survives only on the **manual fallback** form —
  `setEditChrome` shows it when `mode==='form' && !S.editing.id && !S.typeLocked`.

## Duplicates and re-logging

Picking something already in your library **warns rather than blocks** (`showDupe`) and
offers to log it again instead. All three insert paths run `findExisting` first: the
search pick, the manual save, and `addFromViewed`.

- **Re-log** → `saveRelog` appends today's date to `logs`, sorts, points `date_logged` at
  the latest, and **updates** the existing row. It never inserts.
- **Add anyway** → `saveEdit(force)`. `showDupe` replaces `#fields`, which destroys the
  form, so the draft is stashed at `S.dupe.draft` before the swap and read back when
  `force` is set. The click listener is `()=>saveEdit()` on purpose — binding `saveEdit`
  directly would pass the click event as `force` and silently disable the check.
- **Delete a log** → `removeLog(i)` from the item page, confirm-gated, with `logs`
  collapsing back to absent at one entry.

## Currently

`CUR_SLOTS` fixes three slots (Reading / Watching / Playing). `currentByCat` groups
in-progress items, `currentCardsHTML` renders each slot as a **stack** rather than one
tile per item: the front card is in flow, the rest are absolutely positioned behind it
and offset upward.

The peek uses `transform-origin: 50% 0` so the visible sliver equals the translate
exactly (10px / 19px) at any card size — with the default centre origin the scale inset
grows with the card, so a peek tuned at thumbnail size vanishes at full size.

Clicking the peeking back card cycles the stack (`cycleCurrent(k)`, top index in
`S.curTop`) via an invisible `.cyczone` strip above the front card; the count sits in
`.stackn`. Back cards are `pointer-events: none` so only that strip is clickable.

Known gap: finishing a card (✓) clears `in_progress` but does **not** append a log — see
ROADMAP, Lower priority.

## Compare

`tm*` functions: `tmEntries` / `tmIndex` prepare each side, `tmPair` pairs shared works
on `sameWork()`'s two tiers with each item pairing at most once, `tasteMatch` scores, and
`tmPanelHTML` renders the modal. Only items **both users rated on both axes** count, and
under `TM_MIN` shared works the panel says so instead of showing a number. Scoring and
the provisional lean penalty are documented in ROADMAP §2.

## Sheets vs. modals

`openSheet(sel)` / `closeSheets()` drive both, so which one a dialog is comes down to the
class in the markup: `.sheet` slides up from the bottom (add/edit, auth, profile, dev
menu), `.modal` is centred over a scrim (item page, compare, settings, appearance). A
`.modal` must not carry a `.grab` handle — that's the bottom sheet's drag affordance and
reads as broken on a centred pop-up.

Settings holds account state only. Appearance opens from its own header button
(`#themeBtn`), not from Settings, and one-time maintenance tools live in the dev menu
behind the version stamp — currently the needs-rating filter, the rate backlog, and
"Fetch missing covers".
