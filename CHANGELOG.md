# Changelog

All notable changes to this project will be documented in this file.

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
