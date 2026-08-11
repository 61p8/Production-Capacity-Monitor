// LineMaster — one row per Part × Process × Line, with Priority / CT / OA.
// Recommended tidy input: a sheet or table named "LineMaster" in the Master workbook on SharePoint.
// Columns: PartNo, PartName, Model, Process, Line, Priority, CT, OA
//
// HOW TO USE: Get Data → Blank Query → Advanced Editor → paste. Set MasterFileUrl to your file.
// Sign in with an Organizational account when prompted.
let
    // ── Parameter: the SharePoint file URL (right-click the file → Copy link → keep the /.../file.xlsx path)
    MasterFileUrl = "https://YOURTENANT.sharepoint.com/sites/YOURSITE/Shared Documents/Master.xlsx",

    Source   = Excel.Workbook(Web.Contents(MasterFileUrl), null, true),
    // Prefer a named table "LineMaster"; fall back to a sheet of the same name.
    Picked   = try Source{[Item="LineMaster", Kind="Table"]}[Data]
               otherwise Table.PromoteHeaders(Source{[Item="LineMaster", Kind="Sheet"]}[Data], [PromoteAllScalars=true]),

    Typed = Table.TransformColumnTypes(Picked, {
        {"PartNo",   type text},
        {"PartName", type text},
        {"Model",    type text},
        {"Process",  type text},
        {"Line",     type text},
        {"Priority", Int64.Type},
        {"CT",       type number},
        {"OA",       type number}
    }),

    // Guard rails: drop rows with no part / no CT, default OA to 1 where blank.
    Clean = Table.SelectRows(Typed, each [PartNo] <> null and [PartNo] <> "" and [CT] <> null and [CT] > 0),
    OAfix = Table.ReplaceValue(Clean, null, 1, Replacer.ReplaceValue, {"OA"}),
    OAfix2 = Table.ReplaceValue(OAfix, 0, 1, Replacer.ReplaceValue, {"OA"})
in
    OAfix2
