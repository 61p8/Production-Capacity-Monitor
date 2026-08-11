// Load — the fact table. One row per Part × Process × Line × Date, with the row-level Hours and
// PlannedPieces already computed (so DAX only has to SUM). References the LineMaster and Demand queries.
//
// Hours = Qty × Fluct × CT / 3600 / OA          (matches the app exactly)
// PlannedPieces = Qty × Fluct
//
// NOTE: this expands demand onto EVERY line a part can run (all priorities). For the "initial
// allocation" view (each part on its Pri=1 line), use Load_Initial (bottom).
let
    Merged   = Table.NestedJoin(Demand, {"PartNo"}, LineMaster, {"PartNo"}, "LM", JoinKind.Inner),
    Expanded = Table.ExpandTableColumn(Merged, "LM",
        {"PartName", "Model", "Process", "Line", "Priority", "CT", "OA"}),

    AddPcs   = Table.AddColumn(Expanded, "PlannedPieces", each [Qty] * [Fluct], type number),
    AddHrs   = Table.AddColumn(AddPcs, "Hours", each [Qty] * [Fluct] * [CT] / 3600 / [OA], type number),

    Typed = Table.TransformColumnTypes(AddHrs, {
        {"PartNo", type text}, {"PartName", type text}, {"Model", type text},
        {"Process", type text}, {"Line", type text}, {"Priority", Int64.Type},
        {"CT", type number}, {"OA", type number}, {"Qty", type number}, {"Fluct", type number},
        {"Date", type date}, {"Month", type date}, {"PlannedPieces", type number}, {"Hours", type number}
    })
in
    Typed

// ── Create a SECOND query "Load_Initial" (Blank Query) with just:
//        = Table.SelectRows(Load, each [Priority] = 1)
//    Point the measures / visuals at Load_Initial for the un-balanced (initial) capacity picture.
//    Swap in your own pre-computed BALANCED allocation table here if you have one (see README).
