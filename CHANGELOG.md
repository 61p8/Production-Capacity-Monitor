# Changelog

All notable changes to this project will be documented in this file.

## [3.13.0] — 2026-08-06

### Added
- **Separate, editable Day / Week capacity lines.** The monthly steps (417/447/497, WD/OT/holiday)
  didn't map onto a single day, and auto-deriving them from the monthly OT couldn't show a
  *no-OT* line. Week/Day views now use their own line set (`state.subStepConfigs`), independent of the
  monthly steps which are kept exactly as-is for month view. Seeded with **two** lines — **Normal**
  = `hrs/shift × shifts` and **OT** = `(hrs/shift + OT) × shifts` — each scaled by the period's working
  days (day = 1, week = Mon–Fri count). A new **Day / Week capacity lines** editor in Settings lets you
  rename lines, set each line's OT hours, and add/remove lines; the toolbar toggles, threshold tooltip
  and step sequence all follow the active view. Switching Period rebuilds the step sequence (the step
  count can differ between month and day/week). Persisted in localStorage + snapshot; i18n EN/TH/JP.
  Month view is unchanged.

## [3.12.2] — 2026-08-06

### Fixed
- **Day / Week threshold lines now use a physically correct per-day formula.** In sub-month views a
  step threshold was derived by averaging the monthly target over its working days
  (`monthly ÷ WD`), which over-stated any step that includes worked **holidays** — e.g. the 447 step
  became 21.3 h/day, more than a normal day can actually run. A day/week line is now computed straight
  from the day-level parameters: `(hrs/shift + OT) × shifts` per working day (× Mon–Fri count for a
  week); the month-only WD-count and holiday terms are dropped. Steps that differ only by holidays
  therefore collapse to the same day/week line (correct — a normal day is a normal day). The toolbar
  toggle labels and the threshold tooltip now show the day/week value and formula instead of the
  monthly `417/447/497` and its WD/OT/holiday breakdown. **Month view is unchanged.**

## [3.12.1] — 2026-08-06

### Fixed
- **Wide-format Volume files with real *date* columns now enable Week/Day.** v3.12.0 only kept
  day-level detail from the long `Raw_Data` format; a wide grid whose column headers are actual dates
  (one column per day) fell through to the month parser, which collapsed every date to its month and
  disambiguated the collisions as `Aug'26 (2)`, `Aug'26 (3)`… — so `monthlyData.daily` was never
  built and the Period toggle stayed on Month. The wide parser now reads each column header as a real
  date (`rawCellDate`, extended to accept `1-Aug-26` / `1 Aug 2026` / `Aug 1, 2026` text as well as
  Excel dates), **sums** same-month day-columns into one clean month bucket, and records the daily
  detail so Week/Day work. **Re-upload the Volume Excel** into this build to pick it up — an existing
  snapshot can't be retrofitted because its daily detail was never captured.

## [3.12.0] — 2026-07-23

### Added
- **Month / Week / Day views (Phase 1).** A new **Period** toggle on the Results toolbar re-buckets the
  demand into months, ISO weeks, or days and recomputes every step at that granularity — chart, table,
  thresholds, Max Cap, alerts and the Reverse-C/T panel all follow.
  - **Data:** drives off real dates. A `Raw_Data` sheet whose date column holds actual Excel dates
    (or `YYYY-MM-DD`) is now kept at day resolution (`monthlyData.daily`) and rolled up on demand;
    files with only month labels stay month-only (Week/Day disabled, with a hint).
  - **Capacity math is period-generic:** `calculateMaxCap` uses the period's calendar days (month =
    days-in-month, week = 7, day = 1); step thresholds express the monthly target as an
    hours-per-working-day rate and scale by the period's working days (day = 1, week = Mon–Fri count).
  - **Engine:** period keys (`Apr'26` / `2026-W15` / `2026-04-15`) flow through the existing
    month-agnostic pipeline; new helpers `periodType`/`isoWeekKey`/`keyStartDate`/`periodCalDays`/
    `periodWorkDays`/`rebucketDataset`, `monthOrdinal` is now date-based so the three granularities are
    mutually comparable (CT `From <month>` gating still works in week/day view), and the X-axis upper
    tier shows the containing month in week/day view.
  - Persisted in localStorage + snapshot (the daily source travels with the file).
  - **Known limits (Phase 1):** fiscal-year columns (FY27…) have no real dates so they appear in month
    view only; the per-month step-override editor (📅) and month-relabel range stay month-based; the
    Manual tab reloads at its own granularity when you re-open it. Daily view over long ranges shows
    many bars — use the range selector.

## [3.11.0] — 2026-07-23

### Changed
- **Pieces-mode threshold lines are straight again — but still step at a CT change.** Since v3.7.2 the
  step thresholds converted to pieces with each month's *actual* product mix, which made the lines
  wiggle month to month as demand shifted. They now convert with a **fixed product mix** (each part
  weighted by its total pieces over the shown range) while still using **each month's own CT**. So a
  threshold line stays flat while the cycle time is stable and steps cleanly only where CT actually
  changes (e.g. a `From FY28` override) — you get the straight line back *and* the FY28 step. Applies
  to every threshold line (steps + Max Cap) in byPart/byLine and Single/Compare. Bars still use the
  real monthly mix and cell colour is by the hours ratio, so over/under stays truthful. New helpers
  `lineHrsPerPieceStable`/`procHrsPerPieceStable` (`lineMixWeights`/`mixHpp`/`getPartOA`).

## [3.10.1] — 2026-07-23

### Fixed
- **Threshold-line tooltip now shows pieces in Pieces mode.** When the Y-axis was set to
  Pieces/month, hovering a threshold line (steps or Max Cap) still showed only the hour value even
  though the line was plotted in pieces. The tooltip head now shows the plotted value in the active
  unit — e.g. `12,345 pcs (≈ 417 h)` — keeping the hours in parentheses for reference; Hours mode is
  unchanged. Applies to both chart types and Single/Compare; the always-hours Manual tab still shows
  hours.

## [3.10.0] — 2026-07-23

### Added
- **Reverse C/T calculator** (new section on the Results tab). Answers the inverse of the load
  formula: *given a target hours cap, what C/T does each part need?* Pick a process, line, month and a
  target (any configured step / Max Cap / a custom hours value); it reads the line's current monthly
  load and, because load scales linearly with C/T (`hours = Σ qty·Fluct·CT/3600/OA`), reports the
  factor `k = target ÷ current` and each part's **required C/T = current C/T × k**. Shows an OVER /
  within-target badge and "cut every C/T by X%" (or head-room when under). Exact regardless of the
  line's product mix or differing OA; a one-part line gives a single C/T answer. i18n EN/TH/JP.

## [3.9.0] — 2026-07-22

### Added
- **Choose the fill style for "Balanced (moved)" and "Fluctuation buffer".** They were fixed to a
  diagonal hatch and dots; now the 🎨 Colors menu has two dropdowns to pick each role's pattern from
  nine styles — Solid, Diagonal ╱, Diagonal ╲, Cross-hatch, Grid, Horizontal, Vertical, Dots, Big
  dots — so the two overlays can be told apart at a glance. The pattern still uses each part's own
  colour (a white overlay), the mini-legend swatches update to match, and the choice persists in
  localStorage + snapshot. i18n EN/TH/JP.

## [3.8.0] — 2026-07-22

### Added
- **Custom part colours.** A new **🎨 Colors** menu on the chart toolbar lists the parts of the
  current process, each with a colour picker — override the auto-generated colour for any part when
  two hash-picked colours land too close to tell apart. The custom colour still obeys the
  "one Part No. → one colour everywhere" rule (`getPartColor()` checks `state.partColorOverrides`
  first), so it applies across every line, chart, dataset, and the Manual tab. Per-part **Reset to
  auto** (↺) and a **Reset all** button revert to the deterministic hash colour. Choices persist in
  localStorage and in exported snapshots.

## [3.7.2] — 2026-07-22

### Changed
- **Pieces mode: every threshold line now reflects a CT change, not just Max Cap.** In Pieces/month
  view the step thresholds (417 / 447 / 497 …) were converted to pieces with each line's **all-months
  average** hrs/piece — a single flat value — so a mid-timeline CT change (e.g. a `From FY28` override)
  only moved the per-month **Max Cap** line while the step lines stayed flat. All threshold lines
  (steps **and** Max Cap) now convert **per month** — byPart per line via `lineHrsPerPiece`, byLine
  process-wide via `procHrsPerPiece` — so the FY28 CT drop steps up **every** line together, matching
  Max Cap. Lines still read flat while CT and product mix are stable; they step only where the rate
  actually changes. Removed the now-unused averaging helpers (`procHrsPerPieceAvg`,
  `lineHrsPerPieceAvg`, `thHpp`). Hours mode is unaffected.

## [3.7.1] — 2026-07-22

### Fixed
- **CT Period Overrides "From FY28" no longer apply to every month.** A CT change gated on a
  fiscal-year column (`From FY28 → CT = …`) was being applied to the **whole** line — every real
  month plus FY27 — instead of only FY28 onwards. Cause: `getEffectiveCT` gates each change with
  `compareMonths(fromMonth, month)`, but `compareMonths` returned `0` (equal ⇒ "applies") whenever a
  label didn't parse, and fiscal-year labels intentionally don't parse as calendar months. So
  `compareMonths("FY28", anyMonth) <= 0` was always true and the override leaked into all months
  (inflating the whole threshold/hours line in Pieces mode). Introduced a single `monthOrdinal()`
  ordering — real months chronological, fiscal-year columns always **after** every real month and
  ordered among themselves by year (matching how they sit on the X-axis) — and rebuilt
  `compareMonths` on it. All month sorts (parser, calendar grid, range, snapshot) now share this one
  ordering, so FY27 vs FY28 ordering is consistent everywhere.

## [3.7.0] — 2026-07-21

### Added
- **Configurable bar tooltip** (Results chart, Stacked-by-Part). A new **Tooltip** menu on the chart
  toolbar lets you choose which fields the hover tooltip shows — Line & month, Dataset, Part No.,
  Model, Value, C/T (sec/pc), Balanced from, and Fluctuation buffer — with **All / None** shortcuts.
  The choice persists (localStorage + snapshot) and now also applies **inside snapshots** (the menu
  setup runs in both live and snapshot mode). Feature originally contributed by **Sittisak Chuseng
  (PE)**; merged into the main build, fully internationalised (EN/TH/JP), and wired into both the
  Single and Compare chart tooltips.
- **Author credit** in the header subtitle: *Created by Sittisak Chuseng (PE)*.

## [3.6.2] — 2026-07-21

### Fixed
- **Line filter chips now work when line names contain embedded newlines.** Excel line-header cells
  that wrap onto multiple lines produced line names with embedded CR/LF (e.g. `Shaft P Drive⏎P-Type`).
  The filter chips stored the raw name in a `data-line` HTML attribute, but the browser normalises
  `\r\n` → `\n` on attribute read-back, so `chip.dataset.line` no longer matched the raw name in
  `data.lines` and the toggle key never hit — clicking a chip did nothing. Chips now key by **index**
  (`data-idx`) into the lines array instead of round-tripping the name through an attribute, in both
  the Results (`renderLineFilter`) and Manual (`renderManLineFilter`) filters. The Master parser also
  collapses internal whitespace in line names at parse time (`replace(/\s+/g,' ').trim()`) so names
  stay stable across the app.

## [3.6.1] — 2026-07-17

### Changed
- **The Fluctuation buffer is now shown in Hours mode too** (Stacked-by-Part). Previously the dotted
  buffer only appeared in Pieces mode; in Hours the bar showed the total but didn't separate the
  Fluctuation part. The bar's hours are now split proportionally (qty : buffer) into a solid base and
  a dotted Fluctuation slice that still sum to the full hours, and the "Fluctuation buffer" legend
  entry shows in both units whenever the dataset has any Fluct > 1.

## [3.6] — 2026-07-17

### Changed
- **Fluctuation is now a per-part demand multiplier in the Volume file, not a Matrix column.** It was
  a line-side factor in the hours rate, which meant two lines with the *same* CT and OA could show
  very different piece capacities purely because one ran high-Fluctuation parts. Fluctuation now lives
  in the **Monthly/Raw_Data file** as an optional `Fluct` column (per part, blank = 1.0) and multiplies
  the demand: `hours = qty × Fluct × CT / 3600 / OA` (mathematically identical, so **hours and the
  balancing are unchanged**). Consequences:
  - The Matrix no longer has a Fluct column (Master parser ignores it; the Setup "Fluctuation column"
    mapping moved to the Volume side). **Add a `Fluct` column to your Volume file** — otherwise every
    part defaults to 1.0 (the old Matrix Fluct is intentionally *not* used).
  - Pieces mode plots the base `qty` (solid) plus the `qty×(Fluct−1)` **buffer** as a dotted overlay
    in the same colour, with a "Fluctuation buffer" legend entry; the data table shows the adjusted
    total. Because Fluctuation is out of the capacity rate, the per-line piece threshold depends only
    on CT and OA — so lines with equal CT/OA now show the **same** piece capacity.
  - Allocations carry `adjQty = qty × Fluct` through balancing (verified: conserved across steps).
  - Templates updated (Master drops Fluct → v3.0; Monthly/Raw_Data gain a `Fluct` column → v3.0);
    `monthlyData.fluct` persists in localStorage + snapshots.

## [3.5] — 2026-07-17

### Changed
- **Pieces mode is now whole-system and matches the hours view.** Switching the Y-axis to
  Pieces/month now also converts the **data table** (per-line cells and totals show pieces; colour
  still reflects the hours-vs-target ratio). The biggest fix is the **threshold line**: it used one
  process-wide average cycle time, so a fast line like Tube (412h, well under 497h) could show its
  piece bars *above* the flat piece-threshold — a line looked over capacity in pieces while being
  under in hours. Each step/Max-Cap threshold is now converted **per line** using that line's own
  hours-per-piece, so a line's over/under status is identical in pieces and hours (verified across
  all Lathe lines). Non-variant steps use the line's all-months average (flat within the line's
  group); variant steps and Max Cap convert per month. The By-Line chart keeps the process-wide
  average (a single line there can't match every line at once). Diff table stays in hours.

## [3.4.2] — 2026-07-17

### Fixed
- **Balancing used the wrong hours formula when Fluctuation ≠ 1 — parts appeared to lose work when
  moved.** The move/chain-push/Manual code computed a part's hours as `qty×CT/3600 ÷ (OA×Fluct)`,
  but the correct formula (used by the initial allocation) is `qty×CT/3600 ÷ OA × Fluct`. With
  `Fluct = 1.5` a moved part's hours on the destination line came out ~2.3× too small, so its bar
  shrank (looked like the work "disappeared") and — because the numbers were wrong — Smart Balance
  also **over-moved**, pushing far more off the source line than needed. Pieces were always conserved,
  but the hours (and the balance decisions) were wrong. Fixed the divisor to `OA/Fluct` in
  `simulateDirectMove`, `simulateChainPush`, `limitMoveByHours`, and the Manual tab. Files with
  `Fluct = 1` were unaffected. **Re-run Calculate/Balance (and re-export any snapshot) to get corrected
  numbers.**

## [3.4.1] — 2026-07-09

### Fixed
- **Thin part segments no longer vanish in the Stacked-by-Part chart.** The 1px white separator added
  in 3.2.3 was drawn *inside* each bar segment, so a part with a small quantity in a given month
  (a 1–2px tall slice) was completely covered by its own border and rendered invisible — it looked
  like work "disappeared" in some months and reappeared in others as the allocation changed between
  steps. Removed the white border; parts are still distinguished by the (3.2.3) colour hash.

## [3.4] — 2026-07-09

### Added
- **Fiscal-year columns (`FY27`, `FY 28`, `FY2029`, …) are now supported.** Previously the parser only
  accepted month/date headers, so an `FY27` column was silently dropped. These columns already hold a
  monthly-average figure, so they're now parsed and treated exactly like a normal month — same hours
  calculation, same step/Max-Cap thresholds, and they can be balanced — with the X-axis label showing
  `FY27` and the year tier grouping it under its calendar year (FY27 → 2027). Max Cap for an FY column
  uses the 30-day fallback, and the Start→End sequential re-label leaves FY labels untouched.

## [3.3.1] — 2026-07-08

### Fixed
- **Threshold hover tooltip now actually triggers.** On the Stacked-by-Part and Manual charts
  (which use `intersect: true`), the threshold lines had `pointRadius: 0` and so no point to hover —
  the tooltip never appeared. Added `pointHitRadius` to the threshold datasets so hovering the line
  registers.

## [3.3] — 2026-07-08

### Added
- **Manual tab has its own filters, independent of Results.** The Manual chart now carries its own
  threshold-line toggles, Max Cap toggle and line filter (`state.manHidden` / `state.manStepHidden` /
  `state.manShowMaxCap`), so hiding lines or thresholds there no longer touches the Results view and
  vice-versa.
- **Threshold lines show their formula on hover.** Hovering a step (or Max Cap) threshold line pops a
  tooltip with that month's breakdown — work days, OT days × OT h, holidays worked, holiday OT, and
  hours/shift × shifts (Max Cap shows days × (hrs + OT) × shifts). Works on the Results chart (Single
  & Compare, both chart modes) and on the Manual chart.

### Changed
- **Trend line defaults to off**, and the redundant **"Line name" toggle was removed** from the chart
  toolbar (line names are always shown in the axis hierarchy anyway).

## [3.2.5] — 2026-07-08

### Fixed
- **Manual tab now matches the Results chart's month range, line filter and threshold toggles.**
  It plotted every month regardless of the Start→End range, showed lines hidden by the Results line
  filter, and drew every threshold line even when toggled off. Manual now uses `getRangeMonths()`,
  skips lines in `state.hiddenLines`, and honours each step's show toggle + the Max Cap checkbox — so
  switching between Results and Manual shows a consistent view. (The controls live on the Results
  toolbar; Manual mirrors their state.)

## [3.2.4] — 2026-07-08

### Fixed
- **Manual tab now starts from the initial, un-balanced allocation.** It seeded from the currently
  shown step, so opening a snapshot (which lands on the last, fully-balanced step) gave a Manual tab
  that was already balanced with nothing to move. Manual balancing now always loads Step 0 (the raw
  allocation) via `getInitialResult()`, independent of the Results step. Renamed the loader to
  `manLoadInitial()` and relabelled the button "Load initial (unbalanced)".

## [3.2.3] — 2026-07-08

### Changed
- **More distinct part colours when there are many Part No.s.** The per-part colour hash was weak, so
  near-identical numbers (TG-001, TG-002, …) came out almost the same colour. Replaced it with an
  avalanche hash (FNV-1a + finalizer) so a one-character difference scatters the hue across the wheel,
  and widened the saturation/lightness spread so parts that share a hue still differ in shade. Same
  Part No. still maps to the same colour everywhere (invariant unchanged).
- **Thin white separators between stacked part segments** (Stacked-by-Part, Single view) so adjacent
  segments are always visually split even if their colours land close.

## [3.2.2] — 2026-07-08

### Changed
- **Stacked-by-Part tooltip shows only the hovered part, plus its Model.** Hovering a stacked bar
  listed every part in that column; it now shows just the segment under the cursor and appends the
  part's Model from the Master matrix (e.g. `TG-001 · M100: 12.3 h`). Applies to the Single and
  Compare views. (`getPartModel()` looks the Model up from `state.master`, cached per upload.)

## [3.2.1] — 2026-07-08

### Changed
- **Pieces-mode threshold lines stay straight for non-variant steps.** Converting an hour threshold
  to pieces per month made even a constant step (e.g. a flat 417h) look wavy, because each month's
  hours-per-piece differs. Now a step that is *not* a per-month variant (no 📅 override) converts
  with the volume-weighted average hours-per-piece over **all shown months** — one factor, so the
  line is horizontal like it is in hours mode. Per-month variant steps (📅) and Max Cap still convert
  with each month's own factor and vary month by month.

## [3.2] — 2026-07-07

### Added
- **Y-axis unit toggle: Hours ⇄ Pieces/month (Results chart).** A new selector in the chart toolbar
  switches the Results chart between hours and pieces. In Pieces mode the bars show each part's
  monthly quantity, and the existing step threshold lines (417 / 447 / 497 / … and Max Cap) are
  converted from hours to a piece count using each (process, month)'s **volume-weighted average
  hours-per-piece** (`Σ hours ÷ Σ qty`) — so a 417h line becomes "how many pieces 417 hours buys at
  this month's product mix". Works in Single and Compare views, both Stacked-by-Part and By-Line
  charts; tooltips and the axis label follow the unit. The choice persists across sessions.
  (The Diff view stays in hours — it shows an hour delta; the data table also remains in hours.)

## [3.1.1] — 2026-07-07

### Fixed
- **Sticky-header flicker at the bottom of short pages.** The header switched to compact mode at a
  single scroll threshold (60px); on a page barely taller than the viewport, scrolling to the bottom
  landed near that threshold and the compact toggle (which shrinks the header, and the page) bounced
  the scroll back across it, oscillating — the top ribbon appeared to flicker/overlap. Replaced with
  a hysteresis dead zone (enter compact above 140px, leave below 40px).

### Changed
- **Matrix mapping columns now offer `(auto)`** like the Volume side. Part No. / OA / Fluctuation
  default to auto-detection (Part No. also recognises `PRTNO` / `PartNo` / `Item` / … ), so you only
  set them when your headers differ. Existing explicit selections still apply.

## [3.1] — 2026-07-07

### Added
- **Import mapping — tell the app what to read (Setup tab).** Instead of guessing sheet names and
  columns, each uploaded file now shows a small mapping panel populated with the actual sheets and
  header cells from *your* file. Pick from dropdowns and the file re-parses live; the choices are
  remembered as defaults (localStorage + snapshot) for next time.
  - **Matrix:** configure the process-sheet name prefix (default `Matrix -`, now matches any
    keyword/spacing/underscore-or-dash), the Part No. column, the row-2 line marker (default `Pri`),
    and the OA / Fluctuation columns.
  - **Volume:** choose the format (Auto / Wide / Long-Raw_Data), the sheet, the Part / Month / Qty
    columns, and an optional "only parts starting with…" prefix filter.

### Changed
- **Less aggressive auto-scanning.** When a sheet or column is specified in the mapping the parser
  reads exactly that, instead of scanning every sheet and guessing. Auto mode still works when the
  mapping is left blank, so existing files parse unchanged.

### Fixed
- **Removed the hardcoded `TG` part-number filter** in the wide Monthly_Req parser, which silently
  dropped every part whose number didn't start with `TG`. Use the mapping's prefix filter if you
  actually want that behaviour. The wide parser also accepts numeric part numbers now (matching
  Master and Raw_Data).

## [3.0.1] — 2026-07-02

### Fixed
- **Numeric part numbers now parse.** Master and `Raw_Data` rows whose Part No. cell is a number
  (not text) were silently skipped, so a file full of numeric part codes parsed to zero parts and
  looked like a broken upload. Part No. is now coerced to text in both parsers, so `12345` and
  `"PART-001"` both work.
- **Master parse error is now accurate and process-name-agnostic.** Re-uploading a Master that
  parsed to zero parts showed a misleading “check sheet names Matrix - Lathe/Rolling/IHA” message,
  implying those exact process names were required. The parser now reports the real reason (no
  `Matrix - *` sheet / no `Part No.` column / no `Pri`+`C/T` pairs / no valid part rows) with no
  hardcoded process names; the “try other tabs” hint is generic too.

## [3.0] — 2026-07-02

### Added
- **Factory Layout editor (new tab).** Draw a factory layout directly in the app on an SVG canvas:
  create rectangle objects, type them (Area / Walkway / Line, colour-coded), label them, move/resize,
  and combine two or more with **Union/Merge** or **Intersect** (rectilinear boolean via coordinate
  compression). Everything is real-scale — pick mm / cm / m / inch and every number reconverts;
  zoom in/out adjusts the on-screen scale. Layouts persist to localStorage and into snapshots.
  (Linking layout objects to production lines will come later.)
- **Layout navigation & smart snap.** The canvas now pans (middle-drag) and zooms freely
  (mouse wheel around the cursor, a zoom slider, or **Fit** to frame everything) instead of fixed
  pixels + scrollbars. Left-drag empty space marquee-selects; Ctrl/Shift-click adds to the
  selection. A **Snap** toggle aligns object edges & centres while drawing, moving and resizing,
  with on-canvas guide lines.
- **Layout keyboard shortcuts, file save/load, edge dimensions.** Delete/Backspace, Ctrl+Z/Y
  (undo/redo), Ctrl+C/X/V (copy/cut/paste), Ctrl+A (select all), Ctrl+D (duplicate), Esc
  (deselect) and arrow-key nudging all work when the Layout tab is focused. Save/Load a layout as a
  `.json` file (full round-trip) and Export the drawing as an `.svg` image. Each object's width and
  height are now labelled along its top and left edges (instead of the centre) so it's clear which
  number is which axis.
- **Layout grouping, lock & custom styling.** Group/Ungroup objects (Ctrl+G / Ctrl+Shift+G) so they
  select and move together; Lock an object to fix it in place (move/resize/nudge disabled, shown
  with a 🔒). Per-object Fill colour, Border colour and Opacity are editable in the properties panel
  (single or whole selection), with Reset to type defaults. Zoom range widened to roughly
  1 m = 0.4 px (very large floors) up to 1 mm = 6 px (fine detail).
- **Layout z-order & image references.** Reorder overlapping objects with Bring to Front / Forward /
  Backward / Send to Back (toolbar, plus `]` `[` and `Ctrl+]` `Ctrl+[`). Insert an image (🖼) as a
  reference underlay for tracing a layout — dropped at the back, downscaled on import, with an
  adjustable opacity and lockable like any object; it round-trips through save/load and SVG export.
- **Hold Shift to lock aspect ratio** while resizing a Layout object (or image).

### Added
- **Per-month (variable) capacity steps.** Any step can now vary month by month like Max Cap:
  click 📅 on a step row to set that month's work days, OT days, OT h/shift, holidays worked and
  holiday OT individually (empty cells inherit the step's base values). The chart line follows the
  per-month values, and auto-balance targets, overflow alerts and the Manual tab floor all resolve
  per month. Variable steps are marked with `~` (e.g. `417~`); the steps table shows their min–max.
- **Raw_Data auto-import.** Add an optional `Raw_Data` sheet to the Monthly file and paste raw
  long-format records (Part / Month-or-Date / Qty) straight from the production system — the app
  auto-detects the columns (English/Thai/Japanese headers, or by value shape for the month column),
  sums duplicate rows and pivots to parts × months. A non-empty Raw_Data sheet takes priority over
  Monthly_Req; an empty scaffold (as shipped in the template) is ignored.
- **Manual Balance tab.** A separate tab for hands-on load balancing that leaves the auto Smart
  Balance untouched. Load the current step, then hover a bar segment sitting above the chosen
  threshold — Chart.js pinpoints the exact part under the cursor, the lines it can move to blink,
  and a ghost bar previews the new height. Click to open a popup: pick the target line and the
  "reduce line to" value; the source line is reduced to that value and the amount moves across
  (respecting each line's cycle time). Targets may overflow past their cap — you then balance those
  next. Each move is a live what-if on a copy of the result.

### Changed
- **Two-tab layout.** The page is split into a **Setup** tab (upload, preview, settings/steps,
  month labels, Calculate) and a **Results** tab (chart, table, overflow alerts). Calculate jumps
  to Results automatically; snapshots open on Results with Setup hidden. The active tab is
  remembered between sessions.
- **OT days per step.** Each step now has a separate "OT days" field so OT can be applied to only
  some of the work days instead of all of them: `target = [ WD×hrs/shift + OT_days×OT_normal +
  HD×(hrs/shift + Holiday OT) ] × shifts`. Legacy configs without the field fall back to OT_days = WD.
- **Configurable capacity steps.** The fixed 417 / 447 / 497 hour targets are now derived from
  editable per-step inputs (working days, OT/shift on normal days, holidays worked, OT/shift on
  holidays) via `[ WD×(hrs/shift+OT) + HD×(hrs/shift+Holiday OT) ] × shifts`. Steps can be added or
  removed in **Settings → Capacity steps**, making the tool usable across factories with different
  shift/OT structures. Shipped defaults reproduce the original 417 / 447 / 497 targets.
- Threshold chart lines and their toolbar toggles are now generated per configured step.
- `stepConfigs` is persisted to `localStorage` and embedded in exported snapshots.
- **Max Cap OT is now editable.** Max Cap appears as the final row of the steps table with an
  editable OT/shift field; `MaxCap = days_in_month × (hrs/shift + Max Cap OT) × shifts` (every day
  worked). The old fixed `2.5` OT field is gone.
- **Slimmer Settings.** Global inputs reduced to Hours/shift + Shifts. Removed the now-redundant
  "OT (fixed)" and "Default WD" fields and the per-month WD/HD calendar grid (per-month WD had no
  effect on Max Cap, which counts every day of the month). Month re-labeling is kept.
- **Chart range defaults to the current month** (instead of all months), so long datasets no
  longer render every month by default. The Start→End range plus a "This month" shortcut now live
  in Settings → Month labels &amp; graph range (works before Calculate too).

## [2.04] — Initial public release

### Core
- Single-file HTML capacity planning tool — no build step, no dependencies installation
- Multi-process support via Excel `Matrix - <ProcessName>` sheet naming convention
- Smart Balance algorithm with iterative best-move and chain-push (max depth 5)
- Step-based capacity progression: initial → 417h → 447h → 497h → MaxCap

### Data
- Multi-dataset comparison (up to 5 monthly requirement files side-by-side)
- Three view modes: Single / Compare / Diff
- CT step function — Excel `CT_Changes` sheet + in-app overrides (hybrid resolution)
- `localStorage` persistence for master, datasets, settings, notes

### Visualization
- Chart.js stacked bar chart with hierarchical X-axis (month / year / line)
- Auto-switch from month names to month numbers when bars are too narrow
- Vertical separators between line groups
- Threshold lines: 417 (green dashed), 447 (blue dashed), 497 (red solid), Max Cap (red dashed)
- Same Part No. = same color across all lines and charts

### UI
- Tri-lingual (English / Thai / Japanese), all keys synced
- Sticky header with compact mode on scroll
- Five collapsible sections (Upload / Verify / Settings / Results / Alerts) with persisted state
- PPT-style text boxes with 8-direction resize, font/color/list toolbar (ribbon), optional arrow tail
- Snapshot export — embeds all data and pre-computed steps into a self-contained read-only HTML

### Templates
- Auto-generate Master Excel template (3 processes, 8 lines, sample data, CT_Changes example)
- Auto-generate Monthly Requirement Excel template with parsing instructions
