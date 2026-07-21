# Capacity Planning Tool

A single-file HTML application for production capacity planning. Compares monthly demand against line capacity across multiple production processes, with smart load balancing across alternate lines.

**Live demo:** Open `index.html` directly in your browser — no installation required.

---

## Features

- **Single-file deployment** — pure HTML + CSS + JavaScript, no build step, no server required
- **Multi-process support** — define any number of production processes via Excel sheet names (`Matrix - Lathe`, `Matrix - Rolling`, etc.)
- **Multi-dataset comparison** — load up to 5 monthly requirement datasets and compare side-by-side
- **Smart Balance algorithm** — automatically redistributes load to alternate lines (priority 2, 3, ...) when primary lines exceed capacity targets
- **Step-based progression** — Step 0 (initial) → configurable OT-driven targets → MaxCap, with chain-push depth up to 5. Add/remove steps and tune each target from working-day/holiday OT in Settings.
- **Hours ⇄ Pieces Y-axis** — flip the Results chart between load-hours and pieces/month; threshold lines convert via the volume-weighted average cycle time
- **Configurable bar tooltip** — pick which fields the Results chart tooltip shows (part, model, value, C/T, balanced-from, fluctuation buffer, …) from a toolbar menu; the choice is remembered and applies inside snapshots too
- **CT step function** — cycle times can change over time via Excel `CT_Changes` sheet or in-app overrides
- **Snapshot export** — share results as self-contained read-only HTML with embedded data
- **Sticky notes (PPT-style text boxes)** — annotate the dashboard with optional arrow pointers
- **Tri-lingual UI** — English / Thai / Japanese
- **Persistent state** — uploaded files, settings, and notes saved to `localStorage`

---

## Quick start

1. Open `index.html` in a modern browser (Chrome, Edge, Firefox, Safari)
2. Click **Download Master Template** in the upload section to get a sample Excel file
3. Click **Download Monthly Template** for a sample monthly requirement file
4. Upload both files via drag-and-drop
5. Click **Calculate** to generate initial allocation
6. Click **Balance** repeatedly to progress through capacity steps

---

## Import mapping — telling the app what to read

By default the app auto-detects sheets and columns (the conventions below). If your files use
different names, you don't have to rename anything: after you upload a file, a **mapping panel**
appears on the Setup tab, pre-filled with the actual sheets and header cells found in *your* file.
Pick the right ones from the dropdowns and the file re-parses immediately. Your choices are
remembered (localStorage + snapshot) and reused for the next upload.

- **Matrix file:** process-sheet name prefix (default `Matrix -`), Part No. column, the row-2 line
  marker (default `Pri`), and the OA / Fluctuation columns.
- **Volume file:** format (Auto / Wide / Long-`Raw_Data`), which sheet, the Part / Month / Qty
  columns, and an optional "only parts starting with…" prefix filter.

Leave anything on its default / `(auto)` and the built-in detection is used, so the formats below
keep working with no configuration.

## Excel format

### Master file

Contains one sheet per production process, named `Matrix - <ProcessName>` (or any prefix you set in
the import mapping). The process name appears as a tab in the Results section.

| Column | Meaning |
|---|---|
| A | Part No. |
| B | Part Name |
| C | Model |
| D | OA (Operational Availability, e.g. 0.85) |
| E-F | Pri (priority) and CT (cycle time, seconds) for Line 1 |
| G-H | Pri/CT for Line 2 |
| ... | (continue for up to 8 lines) |

> **Fluctuation moved to the Volume file** (v3.6). It is a per-part **demand multiplier**, not a
> line/Matrix property, so it now lives in the Monthly/Raw_Data file (see below). The Matrix no longer
> has a Fluct column.

**Priority numbering:** lower number = preferred line. A part with `Pri=1` on Line 1 starts there. If Line 1 is overloaded, Smart Balance pushes the part to its `Pri=2` line.

### Optional `CT_Changes` sheet

For cycle times that change over time (process improvement, equipment upgrade):

| Part No. | Process | Line | From | New CT |
|---|---|---|---|---|
| PART-001 | Lathe | Line 1 | Jun 2027 | 25.0 |
| PART-001 | Lathe | Line 1 | Jan 2028 | 22.5 |

Step-function semantics: from "From" month onwards, the new CT applies until the next change.

### Monthly Requirement file

A wide-format table with parts in rows and months in columns, plus an optional **`Fluct`** column:

| PRTNO | Fluct | Apr 2027 | May 2027 | Jun 2027 | ... |
|---|---|---|---|---|---|
| PART-001 | 1.5 | 8500 | 9000 | 8800 | ... |
| PART-002 | 1.0 | 5200 | 5100 | 5400 | ... |

Header rows can include `PRTNO` or `Part No.` — the parser auto-detects the header row within the first 15 rows.

**`Fluct` (Fluctuation)** is a per-part **demand multiplier** (blank = 1.0): planned pieces = `qty × Fluct`,
so `hours = qty × Fluct × CT / 3600 / OA`. It used to live in the Matrix; it now belongs with the
demand here. In *pieces* mode the bar shows the base `qty` (solid) plus the `qty×(Fluct−1)` buffer
(dotted, same colour), and because Fluctuation is out of the capacity rate, two lines with the same
CT and OA get the **same** piece capacity.

Month columns accept `Apr 2027`, `Apr'27`, `2027-04`, real Excel dates, **and fiscal-year columns**
`FY27` / `FY 28` / `FY2029`. A fiscal-year column is expected to already hold a **monthly-average**
figure, so it's treated like any other month (same hours math and thresholds); the chart labels it
`FY27` and groups it under its calendar year.

### Raw_Data sheet (optional auto-import)

Instead of filling the Monthly_Req grid by hand, add a sheet named **`Raw_Data`** and paste raw
records from your production system — one row per record, long format:

| Part No. | Fluct | Month | Qty |
|---|---|---|---|
| PART-001 | 1.5 | Apr 2026 | 5000 |
| PART-001 | 1.5 | Apr 2026 | 3500 |
| PART-001 | 1.5 | May 2026 | 9000 |

- Columns are auto-detected by header (`Part No.`/`PRTNO`/`Item`/`Material`…, `Month`/`Date`…,
  `Qty`/`Quantity`/`Plan`…, optional `Fluct`/`Fluctuation` — Thai/Japanese equivalents also work).
  If the month column has no recognisable header, the column whose values parse as months/dates is used.
- Month cells accept labels (`Apr 2026`, `Apr'26`, `2026-04`) or real Excel dates.
- Duplicate part+month rows are **summed**, then everything is pivoted to parts × months.
- If a non-empty `Raw_Data` sheet exists it is used **instead of** Monthly_Req; an empty one is
  ignored, so the template can ship the scaffold safely.

---

## Formula reference

**Hours per part per month per line:**
```
hours = (qty × Fluctuation × CT / 3600) / OA
```
Fluctuation is a per-part demand multiplier from the Volume file (default 1.0); OA and CT are Matrix
(line) properties.

**Monthly capacity (Max Cap):**
```
Max Cap = days_in_month × (hrs_per_shift + Max Cap OT) × shifts
```
- days_in_month = every calendar day worked (pulled automatically from the month)
- Max Cap OT = overtime hours per shift, editable in the Max Cap row of **Settings → Capacity steps**

**Capacity step targets (configurable):**

Each step's hour threshold is derived from a formula you control in **Settings → Capacity steps**:
```
Step target = [ WD × hrs_per_shift + OT_days × OT_normal + HD × (hrs_per_shift + OT_holiday) ] × shifts
```
- WD = normal working days for that step
- OT_days = how many of those work days actually run OT
- OT_normal = overtime hours per shift on an OT day
- HD = holiday days actually worked
- OT_holiday = overtime hours per shift on a worked holiday (on top of a full normal shift)

Steps can be added or removed freely; the final step is always per-month **Max Cap**. The shipped
defaults reproduce the original 417 / 447 / 497 targets at `hrs_per_shift = 7.44`, `shifts = 2`:

**Per-month (variable) steps:** click the 📅 button on a step row to open a month-by-month table
(months come from the uploaded Monthly file) and set that month's WD / OT days / OT h / holidays /
holiday OT individually — empty cells inherit the step's base values. The threshold line then varies
by month (like Max Cap), and balancing, alerts and the Manual tab all use each month's own value.
Variable steps are marked with a trailing `~` (e.g. `417~`).

| Step | WD | OT_days | OT_normal | HD | OT_holiday | Target |
|---|---|---|---|---|---|---|
| 1 | 21 | 21 | 2.5 | 0 | 0   | 417 |
| 2 | 21 | 21 | 2.5 | 2 | 0   | 447 |
| 3 | 21 | 21 | 2.5 | 4 | 2.5 | 497 |
| MaxCap | auto | auto | (Max Cap OT) | — | — | days_in_month × (hrs + Max Cap OT) × shifts |

---

## Architecture

| Layer | Notes |
|---|---|
| Parsing | XLSX (CDN) — auto-detects sheet names matching `Matrix - *` pattern |
| Calculation | Pure JavaScript, runs in-browser. Recursive chain-push limited to depth 5. |
| Charts | Chart.js (CDN), with custom plugin for hierarchical X-axis labels (month / year / line) |
| State | `state` object kept in memory; persisted to `localStorage` (~5MB limit, plenty) |
| Internationalization | Inline i18n dictionary, 3 languages, all UI text mapped to keys |

---

## Customization

The HTML is one self-contained file — open it in any editor to modify. Key constants near the top of the `<script>` block:

```javascript
const LINE_NAMES = ['Line 1', 'Line 2', ...];     // default line names in template generator
const PROCESSES = ['Lathe', 'Rolling', 'IHA'];     // default process names (overridden by Master sheets)
const DEFAULT_STEP_CONFIGS = [...];                 // seed step targets (editable in Settings UI)
const MAX_CHAIN_DEPTH = 5;                          // chain-push recursion limit
const DATASET_COLORS = [...];                       // colors for dataset comparison
```

For deeper customization, the codebase is organized into clearly-labeled sections (Parsers, Calculation, Smart Balance, Rendering, etc.) — search for `// =====` to navigate.

---

## Browser compatibility

Tested in:
- Chrome / Edge 100+
- Firefox 100+
- Safari 15+

Requires `localStorage`, ES2020 syntax, and Chart.js compatible canvas support.

---

## License

[MIT](LICENSE) — use freely, modify freely, no warranty.

---

## Contributing

Pull requests welcome. For larger changes, please open an issue first to discuss.
