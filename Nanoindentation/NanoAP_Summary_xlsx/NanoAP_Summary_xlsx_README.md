## General Info

**Filename:** `NanoAP_Summary_xlsx.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 07-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
Script for converting Anton Paar summary report `.txt` files into
structured Excel and MATLAB formats. The code automatically detects
experiment columns and parameter blocks, organizes each parameter into a
table, and exports results to a multi-sheet `.xlsx` file and a `.mat`
file.

**Inputs:**\
- `inputFile` (string, scalar): Anton Paar summary report `.txt` file
selected via GUI\
- `sampleNames` (cell array, 1 × n): experiment identifiers extracted
from the header

**Outputs:**\
- `.xlsx file` (Excel workbook): one sheet per parameter plus a summary
sheet\
- `.mat file` (MATLAB data): contains `parameterTables`,
`parameterNames`, `parameterUnits`, `summaryTable`, `sampleNames`,
`inputFile`

## Usage

**Example:**

``` matlab
% Run script and select input file when prompted
NanoAP_Summary_xlsx
```

## Parameters

-   `writeExcel`: logical flag to enable or disable Excel export\
-   `writeMat`: logical flag to enable or disable MAT-file export\
-   `parameterTables`: cell array of tables, one per parameter\
-   `parameterNames`: cell array of parameter names\
-   `parameterUnits`: cell array of units\
-   `summaryTable`: table summarizing parameter dimensions

## Dependencies

-   Required toolboxes: none\
-   External functions/files: Anton Paar summary report `.txt` files

## Notes

-   The number of experiment columns is detected automatically.\
-   The number and type of parameters are not predefined.\
-   Empty cells are stored as `NaN`.\
-   Statistical rows such as Mean, Std Dev, Min, Max, N, and Median are
    preserved.\
-   Output files are saved in the same folder as the input file with
    identical base name.\
-   Excel sheet names are sanitized to meet Excel constraints.

## Revision History

-   v1.0 (07-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
