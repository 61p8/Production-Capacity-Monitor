// APPENDIX (optional) — normalise the app's WIDE "Matrix - <Process>" sheets into LineMaster.
// Use this ONLY if you can't produce a tidy LineMaster upstream. It is best-effort and assumes the
// standard layout below; verify against your file and adjust the fixed column count / header rows.
//
// Assumed Master layout per "Matrix - <Process>" sheet:
//   Row 1 : line names sitting above each (Pri, CT) pair
//   Row 2 : sub-headers  ...  Part No. | Part Name | Model | OA | Pri | CT | Pri | CT | ...
//   Row 3+: data
//   Fixed columns A..D = PartNo, PartName, Model, OA ; then repeating (Pri, CT) pairs per line.
//
// Output: PartNo, PartName, Model, Process, Line, Priority, CT, OA  (feed this as LineMaster).
let
    MasterFileUrl = "https://YOURTENANT.sharepoint.com/sites/YOURSITE/Shared Documents/Master.xlsx",
    Source = Excel.Workbook(Web.Contents(MasterFileUrl), null, true),

    // All process sheets (name starts with "Matrix - ").
    Sheets = Table.SelectRows(Source, each [Kind] = "Sheet" and Text.StartsWith([Name], "Matrix - ")),

    // Transform one process sheet (raw, no promoted headers) → tidy rows.
    ProcessSheet = (name as text, grid as table) as table =>
        let
            Process   = Text.AfterDelimiter(name, "Matrix - "),
            Cols      = Table.ColumnNames(grid),
            LineRow   = Record.FieldValues(grid{0}),          // row 1 = line names
            // pair columns start at index 4 (E), step 2: (Pri, CT)
            PairIdx   = List.Transform({0..Number.RoundDown((List.Count(Cols) - 4) / 2) - 1}, each 4 + _ * 2),
            Data      = Table.Skip(grid, 2),                  // data from row 3
            PerLine   = List.Transform(PairIdx, (i) =>
                let
                    lineName = try Text.From(LineRow{i}) otherwise "Line " & Text.From((i - 4) / 2 + 1),
                    t = Table.FromColumns(
                            { Table.Column(Data, Cols{0}), Table.Column(Data, Cols{1}),
                              Table.Column(Data, Cols{2}), Table.Column(Data, Cols{3}),
                              Table.Column(Data, Cols{i}),  Table.Column(Data, Cols{i + 1}) },
                            {"PartNo","PartName","Model","OA","Priority","CT"}),
                    withLine = Table.AddColumn(t, "Line", each lineName, type text),
                    withProc = Table.AddColumn(withLine, "Process", each Process, type text)
                in withProc),
            Combined = Table.Combine(PerLine)
        in Combined,

    All   = Table.Combine(List.Transform(Table.ToRecords(Sheets), each ProcessSheet([Name], [Data]))),
    Typed = Table.TransformColumnTypes(All, {
                {"PartNo", type text}, {"PartName", type text}, {"Model", type text},
                {"Process", type text}, {"Line", type text},
                {"Priority", Int64.Type}, {"CT", type number}, {"OA", type number} }),
    // keep only rows that actually have a Pri and a CT for that line
    Clean = Table.SelectRows(Typed, each [PartNo] <> null and [PartNo] <> "" and [CT] <> null and [CT] > 0 and [Priority] <> null)
in
    Clean
