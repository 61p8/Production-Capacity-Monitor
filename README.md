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

## Excel format

### Master file

Contains one sheet per production process, named `Matrix - <ProcessName>`. The process name appears as a tab in the Results section.

| Column | Meaning |
|---|---|
| A | Part No. |
| B | Part Name |
| C | Model |
| D | OA (Operational Availability, e.g. 0.85) |
| E | Fluctuation factor (e.g. 1.0) |
| F-G | Pri (priority) and CT (cycle time, seconds) for Line 1 |
| H-I | Pri/CT for Line 2 |
| ... | (continue for up to 8 lines) |

**Priority numbering:** lower number = preferred line. A part with `Pri=1` on Line 1 starts there. If Line 1 is overloaded, Smart Balance pushes the part to its `Pri=2` line.

### Optional `CT_Changes` sheet

For cycle times that change over time (process improvement, equipment upgrade):

| Part No. | Process | Line | From | New CT |
|---|---|---|---|---|
| PART-001 | Lathe | Line 1 | Jun 2027 | 25.0 |
| PART-001 | Lathe | Line 1 | Jan 2028 | 22.5 |

Step-function semantics: from "From" month onwards, the new CT applies until the next change.

### Monthly Requirement file

A wide-format table with parts in rows and months in columns:

| PRTNO | Apr 2027 | May 2027 | Jun 2027 | ... |
|---|---|---|---|---|
| PART-001 | 8500 | 9000 | 8800 | ... |
| PART-002 | 5200 | 5100 | 5400 | ... |

Header rows can include `PRTNO` or `Part No.` — the parser auto-detects the header row within the first 15 rows.

### Raw_Data sheet (optional auto-import)

Instead of filling the Monthly_Req grid by hand, add a sheet named **`Raw_Data`** and paste raw
records from your production system — one row per record, long format:

| Part No. | Month | Qty |
|---|---|---|
| PART-001 | Apr 2026 | 5000 |
| PART-001 | Apr 2026 | 3500 |
| PART-001 | May 2026 | 9000 |

- Columns are auto-detected by header (`Part No.`/`PRTNO`/`Item`/`Material`…, `Month`/`Date`…,
  `Qty`/`Quantity`/`Plan`… — Thai/Japanese equivalents also work). If the month column has no
  recognisable header, the column whose values parse as months/dates is used.
- Month cells accept labels (`Apr 2026`, `Apr'26`, `2026-04`) or real Excel dates.
- Duplicate part+month rows are **summed**, then everything is pivoted to parts × months.
- If a non-empty `Raw_Data` sheet exists it is used **instead of** Monthly_Req; an empty one is
  ignored, so the template can ship the scaffold safely.

---

## Formula reference

**Hours per part per month per line:**
```
hours = (qty × CT / 3600) / OA × Fluctuation
```

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
