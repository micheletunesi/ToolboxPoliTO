## General Info

**Filename:** `S2_Minima_selection.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 11-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
Interactive MATLAB script for cropping gridded surface data and
selecting minima regions from user-defined points.

**Inputs:**\
- `data.active.x` (double, m×n): x-coordinates of the grid\
- `data.active.y` (double, m×n): y-coordinates of the grid\
- `data.active.z` (double, m×n): surface values

**Outputs:**\
- `data` (struct): updated dataset with cropped region and minima
ranges\
- `.mat` files: processed data saved to disk\
- `.png` files: plots showing selected regions

## Usage

**Example:**

``` matlab
S2_Minima_selection
```

## Parameters

-   `downsample_step`: subsampling factor for visualization\
-   `folder_source`: input directory with `.mat` files\
-   `folder_output`: directory for processed data\
-   `folder_output2`: directory for exported figures

## Dependencies

-   Required toolboxes:\
    MATLAB base environment (graphics, file I/O)\
-   External functions/files:\
    None

## Notes

Structured grid assumption. User input required via ginput for region
and minima selection. Output folders are created if missing.

## Revision History

-   v1.0 (11-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
