# Changelog

All notable changes to this project will be documented in this file.

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
