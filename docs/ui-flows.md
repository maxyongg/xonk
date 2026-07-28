# UI flows

*Read before touching the add/search flow, the duplicate warning, re-logging or log
deletion, Currently cards, the compare modal's wiring, the CSV import, the pre-auth
welcome screen, or any dialog's sheet-vs-modal presentation. Siblings: `data-model.md`
(what these flows write), `backend.md` (where it goes), `ROADMAP.md` (scoring, what's
next). Keep this current — it is how the next session learns any of it.*

## Welcome (pre-auth)

`renderWelcome()` draws the wordmark, an animated rating graph, and the three buttons;
`initWelcomeHero()` runs the graph. The `o` in the wordmark *is* the four-quadrant
logo, so the reveal lifts it out of the word and grows it into the field — the point is
that a visitor sees xonk rates on **two axes** before they have an account.

- **`header.top` is hidden while signed out.** `render()` toggles it, so demo mode and
  sign-in both bring it back without extra wiring. Nav, search and Add all need an
  account, and the landing carries its own wordmark and buttons. The hero's top padding
  (`min(9vh,80px)`) replaces the space the header used to hold; the handoff's `30px`
  assumed a header above it. Appearance would have gone with the bar, so the landing
  carries its own `#welcomeTheme` — a fixed top-right `.iconbtn`, under the scrim so the
  modal it opens covers it.
- **A theme change has to restyle the plates.** Both inks are baked into each label when
  it's built, and `hCtaTint` reads them per frame — so `applyTheme` calls
  `refreshHeroTheme()`, which re-reads `HERO_INK` and re-runs `hStyleLabel` over the
  live labels. Without it, picking `midnight` from the landing leaves museum-era plates
  on a dark field. Only colours move, so `hDeconflict`'s placement stays valid, and a
  full `render()` (which would replay the 4.3s reveal on every swatch tap) is avoided.
- **The readout has no pre-live copy** — don't restore the handoff's `Tap anywhere on
  the graph to rate`. It sits at full opacity from frame zero, naming a graph that is
  still a dot on the wordmark, and in the two-column layout it floats alone beside empty
  space. The row now fades in at `LIVE` already showing a rating. Its 22px chip holds the
  row's height from the start, so nothing shifts when the text arrives.
- **Two columns above 760px, stacked below.** `.hero-lay` puts the actions beside the
  graph on a desktop so the whole landing sits above the fold; on a phone it stacks. In
  row mode the stage's margin has to be zeroed on *all four* sides — its `auto` side
  margins would otherwise absorb the row's free space and shove the columns apart.
- **The start position is measured, never hardcoded.** Each frame before the lift ends,
  `measure()` compares the `o`'s box to the stage's and derives the translate + scale, so
  the illusion holds at any font size or viewport width. It undoes the translate we
  ourselves applied before measuring — `getBoundingClientRect` returns the *transformed*
  box, and the stage is mid-reveal whenever this re-runs.
- **Colour maths is the app's own** — `quadColorRGB` / `quadColor` / `paintQuadCanvas` /
  `fmtSigned`, and the edge captions reuse `.quad-lab`. A private copy would let the
  hero drift from the picker it is advertising.
- **The tinted Sign in button computes its own ink.** The tint runs near-white at the
  centre to deep blue/magenta at the rim, and one light/dark threshold is not enough —
  mid-luminance tints fail against *both* inks (worst 2.33:1). `hCtaTint` tries both,
  then walks the tint toward the opposite ink until it clears 4.6:1. Both inks come from
  the live theme, not hex, so `midnight` works too. Never put a CSS transition on
  `color` alone: background and ink must land on the same frame or the label crosses
  unreadable mid-greys during a drag.
- **Label plates are placed at runtime.** White text on the bright yellow-green half
  measures ~1.6:1, so each title gets an opaque plate, which must then clear the other
  plates, the four edge captions, *and its own dot* (the dot is the rating). `hDeconflict`
  takes the first candidate slot around the dot that collides with nothing placed yet — so
  the coordinates aren't load-bearing — measuring in the stage's own CSS px (it is scaled
  down at that moment) and re-running on `document.fonts.ready`. Sizes come off the stage,
  not the viewport: it is 300px at every width, so plates are always the compact 11px
  form, `short` where given. At 12px the long titles have no clash-free slot left.
  Changing the anchors, label size or stage size means re-checking: zero label↔label and
  label↔caption overlaps, dot occlusion under ~10%.
- **One loop only.** `render()` calls `stopWelcomeHero()` before it draws anything, so
  signing in, entering the demo, or a second signed-out `render()` can't stack loops. The
  loop is driven by *both* rAF and a 33ms interval, de-duplicated on the wall clock —
  rAF alone stalls while the document is hidden and strands the hero mid-reveal showing a
  half-grown square.
- `prefers-reduced-motion` skips the reveal (the clock starts past it) and parks the idle
  marker instead of drifting it, but keeps presses rippling. Anchors are hardcoded
  (`HERO_ANCHORS`); to make them live, pull five rated items spread across quadrants and
  kinds from the demo-data edge function the way `enterDemo()` does, with the constant as
  the fallback.

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

## Import (Letterboxd / Goodreads CSV)

Opens from **Settings** (`#setImportBtn` → `impOpen`), not the dev menu: every beta
user needs it at onboarding, and nobody finds the version stamp unprompted. One
`.modal.wide` whose body is swapped per step — `impRender` draws pick → preview → run
→ done off `S.imp.step`.

- **The star becomes quality, never enjoyment.** `impStarsToY` maps both services onto
  `quadOf`'s legacy curve (`y = rating/scale*200-100`); Letterboxd's 0.5–5 halves and
  Goodreads' 1–5 wholes both collapse to `stars*40-100`. `rx` stays null, so the row
  draws as a hollow ring, reads as rated, and `needsRating` still returns true — imported
  titles land in the rate backlog, where lockY ("keep this quality, place the enjoyment")
  is already the right gesture. **Don't be tempted to fill `rx` in** — a diagonal
  `rx = ry` would feed compare ~900 opinions the user never expressed.
- **An import can only add.** `impPlan` sorts every candidate into add / update / leave
  alone *before* anything is written, and the preview shows those counts. An update may
  contribute unseen dates to `logs` and a quality to a row with **no** rating at all
  (`ry==null && rx==null`); it never touches a title, a date already held, or a rating
  given by hand.
- **Three Letterboxd files are read**: `watched.csv` (everything seen), `ratings.csv`
  (the star), `diary.csv` (the dates, so re-watches count). `reviews.csv` identifies as
  a diary too — same columns plus `Review` — and its rows duplicate diary ones, which
  the log dedupe absorbs. Any subset works; `watchlist.csv` is the only one refused,
  and it's still *identified* so the preview can name it and say why (`IMP_UNUSED`) —
  a silent drop reads as the import having lost your data.
- **`watched.csv` and `watchlist.csv` have identical headers.** `impIdentify` reads the
  header first (people rename downloads) but has to fall back to the filename for those
  two — a watchlist imported as history is exactly the wrong outcome. Goodreads'
  `to-read` shelf is dropped for the same reason.
- **Which file a date comes from decides what it means, and this is load-bearing.**
  `Watched Date` (diary only) is a real viewing → `logs`. The `Date` column present on
  *every* file is when the entry was created on Letterboxd → `fallback`, never `logs`:
  good enough to date a film arriving fresh, nowhere near good enough to assert a
  re-watch on a film you already own. Collapse that split and every `watched.csv` row
  starts manufacturing a second sitting on films you already have. Goodreads' `Date
  Read` is a real date and merges; its `Date Added` is a fallback.
- **The merge key is kind + normalised name + year, not the Letterboxd URI.** In
  `diary.csv` the URI identifies the *entry*, not the film, so keying on it would give
  one row per sitting.
- `ratings.csv` outranks a diary star — it's your verdict now, not what you thought
  that night. A diary star only fills in when it's the only one there is, latest first.
- **A CSV carries no source id**, which is the one tier `sameWork` matches exactly.
  `impMatchRun` (offered on the done step, and in the dev menu as "Match unlinked items
  to sources") walks every row missing `srcId`, and accepts a hit **only** on an exact
  normalised title with the year within one. Loosen that and you manufacture agreement
  in compare, which is worse than no id. A Goodreads ISBN skips the guessing entirely.
  It's rate-limited, resumable and stoppable — a second tap on the button stops it.
- Goodreads' `Read Count` can say 3 while the export carries one `Date Read`. The other
  sittings aren't invented, so an imported re-read shows as one log. Letterboxd
  re-watches *do* come through, because diary.csv dates each one.
- **The tooltips are tap-toggled, not hover** (`impTip` → `.tip` / `.tip-pop`): the
  export steps are exactly what a phone user needs and phones have no hover. The
  popover is positioned against the whole `<li>`, not the 15px trigger — anchored to
  the trigger it hangs off the panel, since the trigger ends a different-length line in
  every row. The chip stays 15px; a `::after` inset makes the tap target ~33px. The
  Letterboxd one lists the three files against what each brings, as `.tip-f` rows whose
  inner `<b>` must re-declare `display:inline` to beat `.tip-pop b`'s block rule.
- **The done step pushes straight into the rate backlog** (`#impRate` → `openRateQueue`),
  labelled with the live count. Landing ~900 unrated rows and then leaving the user to
  find the backlog on their own is how an import turns into a chore.

## Compare

`tm*` functions: `tmEntries` / `tmIndex` prepare each side, `tmPair` pairs shared works
on `sameWork()`'s two tiers with each item pairing at most once, `tasteMatch` scores, and
`tmPanelHTML` renders the modal. Only items **both users rated on both axes** count, and
under `TM_MIN` shared works the panel says so instead of showing a number. Scoring and
the provisional lean penalty are documented in ROADMAP §2.

## Sheets vs. modals

`openSheet(sel)` / `closeSheets()` drive both, so which one a dialog is comes down to the
class in the markup: `.sheet` slides up from the bottom (add/edit, profile, dev menu),
`.modal` is centred over a scrim (item page, compare, settings, appearance, sign
in / create account). A `.modal` must not carry a `.grab` handle — that's the bottom
sheet's drag affordance and reads as broken on a centred pop-up.

Most modals dismiss from a `Close` in their button row. Auth can't — its row is the mode
toggle plus the submit — so it carries a top-right `.modal-x` instead, styled to match
the rate queue's `.rq-x`.

Settings holds account state **plus the CSV import and the rate backlog** — both are
everyday user surfaces rather than account state, and the dev menu is unfindable by
anyone who wasn't told about the version stamp. `openSet` calls `labelRateQueue`, so
the button answers "how much is left to rate?" without opening anything, and disables
itself at zero. Appearance opens from its own header button (`#themeBtn`), not from
Settings. What's left in the dev menu is genuine maintenance: the needs-rating filter,
"Fetch missing covers" and "Match unlinked items to sources".
