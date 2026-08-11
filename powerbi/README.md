# Power BI starter kit (Approach A) — capacity monitoring from SharePoint

This folder rebuilds the **monitoring** side of the Capacity Planning tool as a native Power BI
model fed from data on SharePoint. It is a **starter kit you assemble in Power BI Desktop** — the
files here are the Power Query (M) queries, the DAX measures, and the model design. There is no
`.pbix` here on purpose (it is a binary Power BI authors; hand-writing one is not reliable).

---

## ⚠️ Read this first — what Power BI can and cannot do

| Capability | Native Power BI (this kit) |
|---|---|
| Demand vs capacity per process / line / period | ✅ |
| Step thresholds (417 / 447 / 497 …) + Max Cap lines | ✅ (DAX measures) |
| Over / under colouring, **% over threshold** | ✅ (conditional formatting) |
| Hours ⇄ Pieces, month / week / day roll-up | ✅ (DAX + a Date table) |
| **Initial allocation** (each part on its `Pri = 1` line) | ✅ |
| **Smart Balance** (move parts across lines, chain-push) | ❌ **not possible in DAX** |
| **Time-Level** (redistribute volume across periods) | ❌ **not possible in DAX** |

**Why the balancing can't be done in DAX:** Smart Balance and Time-Level are *iterative, stateful*
algorithms — they move quantities around and mutate an allocation step by step. DAX is a functional
query language with no mutation/looping-with-state, so it can compute *load and thresholds* but it
cannot *reallocate*.

**If you need the balanced result in Power BI**, compute the balancing **upstream** and store the
result on SharePoint, then point Power BI at that table. Options for the upstream step:
- keep using this HTML app to balance, then export the allocation to SharePoint, or
- run the balancing headless (the algorithm lives in `index.html`) on a schedule, or
- a Power Automate / script job.

Power BI then just *visualises* the pre-computed allocation (swap `Load_Initial` for that table).

---

## Data model (star schema)

```
            ┌─────────────┐        ┌──────────────┐
            │  DimDate    │        │  DimProcess  │
            └──────┬──────┘        └──────┬───────┘
                   │                      │
                   │      ┌───────────────┴───────┐
                   └──────┤        Load           ├───────┐
                          │ (Part×Process×Line×Day)│      │
                          │  Qty, Fluct, CT, OA,   │   ┌──┴────────┐
                          │  Hours, PlannedPieces  │   │  DimLine  │
                          └───────────┬────────────┘   └───────────┘
                                      │
                              ┌───────┴──────┐
                              │   DimPart    │
                              └──────────────┘

   Helper tables (no relationships):  Params (1 row) · Steps (1 row per step)
```

`Load` is a **fact built in Power Query** — every row already carries `Hours` and `PlannedPieces`,
so DAX only has to `SUM`. `Load_Initial` is `Load` filtered to `Priority = 1` (the initial view).

---

## Build steps (Power BI Desktop)

1. **Prepare tidy inputs on SharePoint** (strongly recommended — Power BI hates the wide matrix):
   - `LineMaster` sheet/table: `PartNo, PartName, Model, Process, Line, Priority, CT, OA`
   - `Demand` (or the app's `Raw_Data`): `PartNo, Date, Qty, Fluct`
   - Put both in a workbook (or two) in a SharePoint document library.
   - If you can only export the app's **wide** Matrix, see `powerquery/Matrix_Unpivot_appendix.pq`
     to normalise it to `LineMaster` — but producing `LineMaster` directly upstream is cleaner.
2. **Get Data → Blank query**, open the Advanced Editor, and paste each `.pq` file:
   - `LineMaster.pq`, `Demand.pq`, then `Load.pq` (it references the first two).
   - Set the `...FileUrl` parameters at the top of each query to your SharePoint file URLs
     (Home → Manage Parameters, or edit inline). Use an **Organizational account** sign-in.
3. **Create the helper tables** (Home → Enter Data):
   - `Params`: one row — `HrsPerShift = 7.44`, `Shifts = 2`, `MaxCapOT = 0`.
   - `Steps`: one row per capacity step — columns `Step, Name, WD, OTdays, OTnormal, HD, OTholiday`.
     Shipped defaults (reproduce 417 / 447 / 497 at 7.44 h × 2 shifts):

     | Step | Name | WD | OTdays | OTnormal | HD | OTholiday |
     |---|---|---|---|---|---|---|
     | 1 | OT a | 21 | 21 | 2.5 | 0 | 0 |
     | 2 | OT b | 21 | 21 | 2.5 | 2 | 0 |
     | 3 | OT c | 21 | 21 | 2.5 | 4 | 2.5 |
4. **Date table**: Modeling → New Table → paste `DimDate` from `dax/Measures.dax` (top). Mark as
   date table. Relate `DimDate[Date]` → `Load[Date]`.
5. **Model relationships**: `Load[PartNo]→DimPart[PartNo]`, `Load[Process]→DimProcess[Process]`,
   `Load[Line]→DimLine[Line]` (create the Dim tables as distinct values of `Load`, or let Power BI
   auto-create). `Steps`/`Params` stay **unrelated** (used only by measures via `SELECTEDVALUE`).
6. **Measures**: paste everything in `dax/Measures.dax` (one measure at a time, or via Tabular Editor).
7. **Visuals**:
   - Clustered column chart: Axis = `DimDate[Month]` (or Week/Day), Legend = `DimPart[PartNo]`,
     Values = `[Load Hours]` (or `[Planned Pieces]`), small multiples = `DimLine[Line]`.
   - Add threshold **reference lines**: Analytics pane → Constant/So — or plot `[Step Target]` /
     `[Max Cap]` as line measures on a combo chart.
   - **% over**: conditional formatting on the value using `[% Over vs Step]` (font/background).
   - Slicers: Process, Line, Step (single-select on `Steps[Step]`), date range.
8. **Refresh from SharePoint**: publish to the Power BI Service, set the dataset credentials
   (Organizational account) and a **scheduled refresh**. (Power Automate can also drop fresh files
   on SharePoint before the refresh — see the repo's main README discussion.)

---

## Files

| File | Purpose |
|---|---|
| `powerquery/LineMaster.pq` | Load the tidy line master from SharePoint |
| `powerquery/Demand.pq` | Load demand (Raw_Data long, or wide) from SharePoint |
| `powerquery/Load.pq` | Merge → the `Load` fact with row-level `Hours` / `PlannedPieces` |
| `powerquery/Matrix_Unpivot_appendix.pq` | Best-effort: normalise the app's **wide** Matrix → `LineMaster` |
| `dax/Measures.dax` | `DimDate`, Load/thresholds/Max Cap/% over measures |

## Quick validation with the sample data

`sample/LineMaster.csv` + `sample/Demand.csv` let you test the model without SharePoint: Get Data →
Text/CSV for each, then build `Load` by merging them (same steps as `Load.pq`, just swap the sources).

Sanity check — one row: `P-001` on its `Pri = 1` line (`Shaft Armature Line 1 Robot`), 2026-08-03,
`Qty 9000 × Fluct 1 × CT 120 / 3600 / OA 0.9 = 333.3 h`. The whole `Shaft Armature Line 1 Robot` line
for **Aug 2026** should total `Load Hours ≈ 1,285 h` (9000+8500+9200+8000 = 34,700 pcs at the same rate).

## The formulas mirror the app exactly:
```
Hours          = Qty × Fluct × CT / 3600 / OA
Step target    = (WD×h + OTdays×OTnormal + HD×(h+OTholiday)) × shifts      (h = HrsPerShift)
Max Cap        = DaysInMonth × (h + MaxCapOT) × shifts
```
