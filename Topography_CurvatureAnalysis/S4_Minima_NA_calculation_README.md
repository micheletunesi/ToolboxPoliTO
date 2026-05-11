## General Info

**Filename:** `S4_Minima_NA_calculation.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 11-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
This script processes linearized surface data to compute geometric
features. It identifies minimum curvature points within predefined
ranges and calculates NA crossing points from slope-angle profiles.

**Inputs:**\
- `data.curvature` (double, m×n): curvature values\
- `data.slope_angle` (double, m×n): slope angle values in degrees\
- `data.axes.x` (double, m×n): x-coordinates\
- `data.axes.y` (double, m×n): y-coordinates\
- `data.minima_selection` (struct): minima bounds (sx, dx)

**Outputs:**\
- `data` (struct): updated with minima_calc and NA fields\
- `.mat` files: processed datasets\
- `.png` files: global plots for minima and NA

## Usage

**Example:**

``` matlab
S4_Minima_NA_calculation
```

## Parameters

-   `NA_value`: threshold for NA crossing\
-   `NA_angle`: corresponding angle (asind(NA_value))\
-   `fields_to_remove`: unused fields removed before saving

## Dependencies

-   Required toolboxes:\
    MATLAB base environment (graphics, file I/O)\
-   External functions/files:\
    findCrossing (required for NA computation)

## Notes

Structured grid assumption. Minima are computed as curvature minima
within selected ranges. NA points are determined as slope-angle
crossings. Output folders are created if missing.

## Revision History

-   v1.0 (11-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
