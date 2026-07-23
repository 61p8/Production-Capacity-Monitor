# CLAUDE.md

Context and conventions for AI-assisted development on this repository.

---

## Project at a glance

**What:** Single-file browser-based capacity planning tool. Compares monthly production demand against multi-line capacity targets, with iterative load balancing across alternate lines.

**Why single-file:** Zero install, zero build, runs in any modern browser by opening `index.html` directly. The user base is production engineers — most cannot install Node/Python on factory machines. Do not break this property.

**Stack:** HTML + CSS + Vanilla JavaScript (ES2020) + Chart.js (CDN) + SheetJS XLSX (CDN). No bundler, no transpiler, no framework.

---

## File layout

```
index.html        ← entire app (HTML + CSS + JS in one file, ~3,700 lines)
README.md         ← end-user docs (features, Excel format, formula)
CHANGELOG.md      ← versioned change log
LICENSE           ← MIT
.gitignore        ← excludes *.xlsx test files and snapshot exports
```

When adding new files, prefer keeping logic in `index.html`. Only split out if a clear reusable boundary emerges (e.g., a worker script for heavy computation).

---

## Code organization inside `index.html`

The single `<script>` block is structured into clearly-labeled sections. Search for `// =====` to navigate:

| Section | Purpose |
|---|---|
| State + Constants | `state` object (incl. `state.stepConfigs`, `state.maxCapOT`), `PROCESSES`, `LINE_NAMES`, `DEFAULT_STEP_CONFIGS`, `STEP_LINE_STYLES`, `DATASET_COLORS`, `MAX_CHAIN_DEPTH` |
| I18N | `I18N.en` / `I18N.th` / `I18N.jp` dictionaries — **all keys must exist in all three** |
| Helpers | `t()`, `$()`, `formatHours()`, `parseMonthLabel()`, `getDisplayLabel()`, `compareMonths()`, color hash, fill-pattern engine (`PATTERN_STYLES`, `buildPatternCanvas()`, `makePattern()`; `getHatchPattern()`/`getDotPattern()` resolve the user-chosen `state.patternStyles.balanced`/`.buffer`; `patternDataURL()`/`updateLegendSwatches()` sync the mini-legend), pattern cache |
| CT Step Function | `getEffectiveCT()` resolves CT in priority order: App override → Excel CT_Changes → Matrix base |
| Chart helpers | `xHierarchyPlugin`, `computeXHierarchy()`, `shouldUseNumericMonths()`, `getMonthOnly()` |
| Parsers | `parseMaster(wb, map)`, `parseMonthly(wb, map)`, `parseRawData(wb, map)` — all take `state.importMap`; blank fields fall back to auto-detection. `matchSheetPrefix()` resolves the process-sheet prefix |
| Import mapping | `state.importMap` (`{master, volume}`, see `DEFAULT_IMPORT_MAP`) — user config on Setup for what the parsers look for. `renderImportMapMaster/Volume()`, `reparseMaster/Volume()`, `setupImportMap()`, `wbHeaderCandidates()`. Persisted (localStorage + snapshot) |
| Fluctuation | Now a **demand multiplier from the Volume file** (`monthlyData.fluct`, per part), NOT a Matrix column. `resolvePartsFluct()` folds it into `pd.fluct` at calc time (hours unchanged: `qty×Fluct×CT/3600/OA`). Allocs store `adjQty = qty×Fluct` (`addToAlloc`/moves carry it); pcs mode plots `qty` (base) + `adjQty−qty` (Fluct buffer, dotted). Missing → 1.0 (never the Matrix value) |
| Calculation: Initial | `calculateInitialAllocation()` — assigns each part to its `Pri=1` line per process |
| Smart Balance | `calculateForStep()`, `smartBalanceV2()`, `simulateDirectMove()`, `simulateChainPush()`, `limitMoveByHours()` |
| Rendering | `renderPreview()`, `renderCalendarGrid()`, `renderTableArea()`, `renderChart()`, `renderResults()`, etc. |
| Y-axis unit | `state.yUnit` (`'hours'`/`'pcs'`) toggles the Results chart + table between hours and pieces. Helpers: `getYUnit()`, `allocBarVal()`, `lineBarVal()`, `lineQtyTotal()`, `procHrsPerPiece()` (process-wide per-month, byLine thresholds), `lineHrsPerPiece()` (**per-line** per-month hrs/piece — byPart threshold conversion, so pcs over/under matches hours), `thPieces()` (hours→pieces via a supplied factor), `fmtY()`/`fmtCellY()`, `yAxisTitle()`. **All** threshold lines (steps + Max Cap) convert **per month** (byPart: per line via `lineHrsPerPiece`; byLine: process-wide via `procHrsPerPiece`), so a CT change — e.g. an override `From FY28` — steps every threshold line, not just Max Cap. (Before v3.7.2 non-variant steps used an all-months avg → flat, which hid CT steps; that avg path and its helpers `procHrsPerPieceAvg`/`lineHrsPerPieceAvg`/`thHpp` were removed.) Tables show pieces (colour still by hours ratio); Diff table stays in hours |
| Reverse C/T | `revPopulate()`, `renderReverseCT()`, `setupReverseCT()`, `getBaseCT()`, `revTargetList()` — inverse of the load formula: target hours → required C/T per part (reqCT = curCT × target/currentHours, exact since load ∝ CT). Reads the active dataset's current result; UI in `#revCtSection` on Results. `state.rev = {proc,line,month,targetKey}` (ephemeral) |
| Text Boxes | `addNote()`, `renderNotes()`, `wireNote()`, `renderTails()` — PPT-style annotations |
| Snapshot | `exportSnapshot()`, `loadSnapshotIfPresent()`, `applySnapshotMode()`, `buildSnapshotPayload()` |
| Setup | `setupEvents()`, `setupUpload()`, `setupCollapsibleSections()`, `init()` |

---

## Critical invariants — do not break

1. **Same Part No. = same color across all lines, all charts, all datasets.** Implemented via deterministic HSL hash in `getPartColor()`. Cached in `state.partColors`. Never assign random colors to parts; never override this elsewhere. The **only** sanctioned override is a user custom colour in `state.partColorOverrides` (`{ [partNo]: '#hex' }`, edited via the 🎨 Colors menu on the chart toolbar) — `getPartColor()` checks it first, so a custom colour still maps one Part No. → one colour everywhere. Persisted in localStorage + snapshot; `getPartColorHex()`/`hslToHex()` back the `<input type=color>`.

2. **i18n keys stay in sync.** Whenever you add user-facing text, add the key to `I18N.en`, `I18N.th`, AND `I18N.jp`. A missing key falls back to the key string itself, which is bad UX.

3. **`saveStorage()` is a no-op in snapshot mode.** Anything that mutates state in snapshot mode must check `state.isSnapshot` first. The snapshot file is meant to be a frozen view.

4. **Threshold lines in Chart.js need unique stack names.** A bug in v1.3 caused threshold lines to stack on top of bars when they shared a stack. Each step threshold line uses a per-step `stack` of `'th_step<idx>'` (and Max Cap uses `'th_mc'`) — unique even when two steps compute the same hour value. Don't merge them or key the stack off the (possibly duplicate) hour label.

5. **Run `node --check` after every batch of script edits.** The whole app is one inline script — a syntax error anywhere breaks everything. Workflow:
   ```bash
   # Extract inline script and validate
   python3 -c "
   import re
   with open('index.html') as f: html = f.read()
   m = re.search(r'<script>(?!\s*src)(.+?)</script>', html, re.DOTALL)
   open('/tmp/check.js', 'w').write(m.group(1))
   " && node --check /tmp/check.js
   ```

6. **Process names are dynamic, not hardcoded.** Use `getProcesses()` which returns `state.master.processList || PROCESSES`. The `PROCESSES` constant is only a fallback for the template generator. Never write `for (const proc of PROCESSES)` outside that fallback context.

7. **The Master file's `Matrix - <Name>` sheet naming convention defines processes — but it's now the _default_, not a hardcode.** The prefix lives in `state.importMap.master.sheetPrefix` (default `Matrix -`) and is matched via `matchSheetPrefix()`; the user can override it (and the Part No. / OA / Fluctuation columns and `Pri` marker) in the Setup import-mapping panel. Volume files are the same via `state.importMap.volume`. When changing the defaults or the convention, update `DEFAULT_IMPORT_MAP`, `README.md`, the template generator's instructions sheet, and the i18n error messages in all three languages. Do NOT reintroduce hardcoded column labels or part-number prefixes in the parsers — thread them through `importMap`.

8. **Bump the version on every change.** `APP_VERSION` (a `const` near `STORAGE_KEY` in `index.html`) is the single source of truth for the user-facing version; the header subtitle renders `v${APP_VERSION}` from it, so bump that one constant — don't hardcode a version anywhere else. See **Versioning** below.

---

## Versioning

Every change that ships must bump `APP_VERSION` and add a matching `CHANGELOG.md` entry — no silent edits.

- **Where:** `const APP_VERSION` in `index.html` (drives the header subtitle). Nothing else hardcodes the app version.
- **How much:** `MAJOR.MINOR` — MINOR for a new feature or notable change, MAJOR for a large module / breaking change; a `.patch` third segment is fine for small fixes (e.g. `3.0.1`).
- **CHANGELOG:** add the change under a heading for the new version with today's date (move items out of `[Unreleased]` when you assign a number). Match the version you set in `APP_VERSION`.
- **Do NOT** bump the data-format versions for feature work — those are independent and change only when their own format changes:
  - snapshot payload `version` (in `buildSnapshotPayload`) — the embedded-state schema
  - layout file `version` (in `laySaveFile`) — the `.json` layout format
  - Excel template titles (`downloadMasterTemplate` / `downloadMonthlyTemplate`) — the spreadsheet layout

## Core formulas

```
Hours per part per month per line:
  hours = (qty × Fluctuation × CT / 3600) / OA
  where  Fluctuation is a per-part DEMAND multiplier from the Volume file (monthlyData.fluct),
         default 1.0. adjQty = qty × Fluctuation = the planned pieces (what pcs mode plots).
         Note: OA and CT stay per line/process (Matrix); Fluctuation is NOT a Matrix column anymore.

Monthly max capacity:
  MaxCap = days_in_month × (hrs_per_shift + maxCapOT) × shifts
  where  days_in_month = every calendar day worked (auto from the month)
         maxCapOT = state.maxCapOT, editable in the Max Cap row of the steps table
```

Step targets are **user-configurable** (not hardcoded). `state.stepConfigs` holds one entry per
middle step `{ wd, otDays, otNormal, hdWorked, otHoliday }`; `getStepDefs()` wraps them with a
leading Initial step and a trailing Max Cap step. Each middle step's hour threshold:
```
  threshold = [ WD × hrs_per_shift + otDays × otNormal + HD × (hrs_per_shift + otHoliday) ] × shifts
  (computeStepThreshold; otDays defaults to wd for legacy configs missing the field)
```
A step may also carry **per-month overrides** in `cfg.perMonth = { [monthKey]: {wd, otDays, otNormal,
hdWorked, otHoliday} }` (edited via the 📅 button per step row; fields left empty inherit the base).
`computeStepThresholdMonth(cfg, setting, month)` resolves the effective threshold; balance targets,
alerts, chart lines and the Manual tab all go through it, so a variable step's line moves month by
month (labelled with a trailing `~`). `readSettings()` deep-copies `stepConfigs` for this reason.
- Step 0 = Initial (no balance applied; overflow compared against the first configured step)
- Steps 1..N = computed from `state.stepConfigs` (edited in Settings → Capacity steps; add/remove allowed)
- Final step = MaxCap (per-month from settings)

`DEFAULT_STEP_CONFIGS` seeds three steps that reproduce the legacy 417 / 447 / 497 targets at
`hrs_per_shift = 7.44`, `shifts = 2`. `stepConfigs` is persisted via `readSettings()` (storage +
snapshot) and restored in `applySavedSettings()` / `loadSnapshotIfPresent()`. Threshold chart lines
and their toolbar toggles are generated dynamically (`getStepThresholds()`, `renderStepToggles()`);
each line keeps a unique `stack: 'th_step<idx>'` (see invariant #4).

---

## Smart Balance algorithm (high-level)

For each (process, month) where any line exceeds the current step's target:

1. Identify "donor" lines (over target) and their over-hours.
2. Identify candidate parts that could move (have a `Pri ≤ current_step_pri` alternate line).
3. Pick the best move by ranking: `gain DESC → partFlex DESC → chainDepth ASC`.
4. Try `simulateDirectMove` first — directly shift qty to backup line if it has space.
5. If backup is also full, try `simulateChainPush` recursively (max depth 5, controlled by `MAX_CHAIN_DEPTH`).
6. If chain depth exceeds 5, mark `result.chainExceeded = true` and surface a UI warning.

The algorithm uses `getEffectiveCT(part, process, line, month, baseCT)` for all CT lookups so step-function CT changes apply correctly per month.

---

## Adding a new feature — checklist

When adding any user-visible feature:

- [ ] UI element added to `index.html` body
- [ ] Event handlers wired in `setupEvents()` or a dedicated setup function
- [ ] State mutations go through helpers that call `saveStorage()` (gated by `!state.isSnapshot`)
- [ ] i18n keys added to all three dictionaries (`en`, `th`, `jp`)
- [ ] If snapshot-relevant: serialize in `buildSnapshotPayload()`, deserialize in `loadSnapshotIfPresent()`, hide/disable in `applySnapshotMode()`
- [ ] If chart-related: re-test all 3 view modes (Single, Compare, Diff) and both chart types (byPart, byLine)
- [ ] If calculation-related: confirm step-function CT still works (test by adding a row to Excel `CT_Changes` and an App-layer override)
- [ ] Run `node --check` on extracted script
- [ ] Manual smoke test: upload sample Master + Monthly, calculate Step 0, click Balance through to Step 4, switch tabs, switch languages, export snapshot, reopen snapshot

---

## Adding a new language

1. Add a new key under `I18N` with the same shape as `en`. Example: `I18N.de = { app_title: '...', ... }`.
2. Add a language button in the header next to the existing three (look for `data-lang="en"`).
3. Style the new button consistently.
4. Update the language fallback chain in `t()` if needed.
5. Test that switching to the new language updates every visible element with a `data-i18n` attribute.

---

## Adding a new process or line

**Processes** are dynamic — discovered by parsing `Matrix - <Name>` sheet names in the uploaded Master file. To add one, the end user just adds a new sheet to their Excel; no code change required.

**Lines** are also defined per part in the Master file's column structure (`Pri` / `C/T` column pairs). The `LINE_NAMES` constant only affects the template generator.

If you need to support more than 8 lines per process in the template generator, update `LINE_NAMES` and adjust the column ranges in `downloadMasterTemplate()`.

---

## Snapshot mode mental model

A snapshot is the app with embedded data: same HTML file + a `<script id="__snapshot__" type="application/json">` tag injected into `<head>` containing the entire state.

On load, `loadSnapshotIfPresent()` checks for this tag and switches the app into read-only mode by:
- Setting `state.isSnapshot = true`
- Hiding upload, settings, and action buttons via `applySnapshotMode()`
- Skipping `saveStorage()` writes
- Pre-computing all 5 steps for all datasets at export time, so the recipient can click through steps without recalculation

When changing core behavior, ask: "does this still work correctly when re-opening a snapshot?" If unsure, export a snapshot, close the tab, re-open the file, and verify.

---

## Things to NOT do

- **Don't add a build step.** No webpack, no Vite, no TypeScript, no Tailwind compiler. The whole point is `index.html` is self-contained.
- **Don't introduce frameworks** (React, Vue, Svelte). The codebase is intentionally vanilla.
- **Don't use `localStorage` in artifacts intended to ship as snapshots.** Snapshots run from the user's filesystem and the storage scope is per-origin — `file://` works inconsistently across browsers. The snapshot path uses in-memory state only.
- **Don't change the Excel format without migration.** Existing user files must continue to parse. The parser is forgiving (auto-detects header row, falls back gracefully) — keep it that way.
- **Don't ship CDN dependencies as a vendored copy without good reason.** CDN is fine; users have internet. Vendoring inflates the file size and complicates audits.
- **Don't add tracking, analytics, or external API calls.** Tool runs entirely client-side and should stay that way.

---

## Quick commands

```bash
# Open the app
open index.html              # macOS
xdg-open index.html          # Linux
start index.html             # Windows

# Validate JS syntax
python3 -c "
import re
with open('index.html') as f: html = f.read()
m = re.search(r'<script>(?!\s*src)(.+?)</script>', html, re.DOTALL)
open('/tmp/check.js', 'w').write(m.group(1))
" && node --check /tmp/check.js

# Count lines
wc -l index.html

# Find a function quickly
grep -n "^function " index.html

# List all i18n keys
grep -oE "'[a-z_][a-z0-9_]*:'" index.html | sort -u
```

---

## When asking the user for clarification

This project's primary developer prefers terse, directive communication. When uncertainty arises:
- Ask one focused question, not a list of five.
- Offer 2–3 concrete options, not open-ended exploration.
- If the change is small and the choice is obvious, just make it — don't ask.
- If the change affects multiple files or invariants above, ask first.
