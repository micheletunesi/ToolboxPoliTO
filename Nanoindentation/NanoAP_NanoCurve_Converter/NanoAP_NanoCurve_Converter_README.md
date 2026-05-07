## General Info

**Filename:** `NanoAP_NanoCurve_Converter.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 07-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
Batch processing script for NanoAP indentation .txt files. The script
extracts numeric data from the "Measured values" section, parses time,
depth, and force columns, and saves each dataset as a .mat file. An
optional preview of force vs depth is displayed for each processed file.

**Inputs:**\
- `folderPath` (string, scalar): directory selected via GUI containing
.txt files\
- `baseName` (string, scalar): user-defined prefix for output filenames\
- `showPreview` (logical, scalar): flag to enable or disable plotting

**Outputs:**\
- `.mat files` (time, depth, force vectors): saved in "Processed"
subfolder

## Usage

**Example:**

``` matlab
% Run script and follow prompts
```

## Parameters

-   `numericRowPattern`: regular expression used to detect numeric data
    rows\
-   `pause duration`: fixed at 3 s for preview display\
-   `output naming`: `<baseName>`{=html}\_`<number>`{=html}.mat
    extracted from filename

## Dependencies

-   Required toolboxes: none\
-   External functions/files: Indentation curves in .txt format from
    Anton Paar software

## Notes

-   The script assumes fixed column ordering: column 1 = time, column 2
    = depth (nm), column 3 = force (mN)\
-   Decimal commas are converted to decimal points before parsing\
-   Files without a "Measured values" section or valid numeric data are
    skipped\
-   Output numbering is extracted from trailing digits in the filename

## Revision History

-   v1.0 (07-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
