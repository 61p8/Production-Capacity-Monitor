// Demand — one row per Part × Date, with Qty and the per-part Fluctuation multiplier.
// Primary input: the app's long "Raw_Data" sheet  →  Part No. | Fluct | Date | Qty
//   * Use REAL dates (or YYYY-MM-DD) so Power BI can roll up to Month / Week / Day.
//   * Fluct blank ⇒ 1.0 (a demand multiplier: planned pieces = Qty × Fluct).
// If you only have a WIDE month-column grid, see the unpivot note at the bottom.
let
    VolumeFileUrl = "https://YOURTENANT.sharepoint.com/sites/YOURSITE/Shared Documents/Volume.xlsx",

    Source  = Excel.Workbook(Web.Contents(VolumeFileUrl), null, true),
    Raw     = try Source{[Item="Raw_Data", Kind="Table"]}[Data]
              otherwise Table.PromoteHeaders(Source{[Item="Raw_Data", Kind="Sheet"]}[Data], [PromoteAllScalars=true]),

    // Normalise likely header spellings to PartNo / Fluct / Date / Qty.
    Ren = Table.RenameColumns(Raw, {
        {"Part No.", "PartNo"}, {"PRTNO", "PartNo"}, {"Item", "PartNo"}, {"Material", "PartNo"},
        {"Fluctuation", "Fluct"}, {"Month", "Date"}, {"Quantity", "Qty"}, {"Plan", "Qty"}
    }, MissingField.Ignore),

    Typed = Table.TransformColumnTypes(Ren, {
        {"PartNo", type text}, {"Fluct", type number}, {"Date", type date}, {"Qty", type number}
    }),

    Clean   = Table.SelectRows(Typed, each [PartNo] <> null and [PartNo] <> "" and [Qty] <> null and [Qty] > 0),
    Fluct1  = Table.ReplaceValue(Clean, null, 1, Replacer.ReplaceValue, {"Fluct"}),
    AddMon  = Table.AddColumn(Fluct1, "Month", each Date.StartOfMonth([Date]), type date)
in
    AddMon

// ── WIDE grid instead of Raw_Data?  Replace the "Raw" step with the sheet, then:
//    Table.UnpivotOtherColumns(<table>, {"PartNo","Fluct"}, "Date", "Qty")
//    and parse the month-label columns to dates before typing.
