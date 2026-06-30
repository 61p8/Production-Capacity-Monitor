# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **Factory Layout editor (new tab).** Draw a factory layout directly in the app on an SVG canvas:
  create rectangle objects, type them (Area / Walkway / Line, colour-coded), label them, move/resize,
  and combine two or more with **Union/Merge** or **Intersect** (rectilinear boolean via coordinate
  compression). Everything is real-scale — pick mm / cm / m / inch and every number reconverts;
  zoom in/out adjusts the on-screen scale. Layouts persist to localStorage and into snapshots.
  (Linking layout objects to production lines will come later.)

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
