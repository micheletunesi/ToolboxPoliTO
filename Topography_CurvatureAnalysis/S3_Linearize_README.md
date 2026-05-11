## General Info

**Filename:** `S3_Linearize.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 11-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
This script processes cropped surface data with predefined minima
ranges. It performs local linear fitting, computes slope and slope
angle, and derives curvature profiles. Results and diagnostic plots are
saved.

**Inputs:**\
- `data.active.x` (double, m×n): x-coordinates of the grid\
- `data.active.y` (double, m×n): y-coordinates of the grid\
- `data.active.z` (double, m×n): surface values\
- `data.minima_selection` (struct): minima bounds (sx, dx)

**Outputs:**\
- `data` (struct): includes linear, slope, slope_angle, curvature, axes\
- `.mat` files: processed datasets\
- `.png` files: diagnostic plots

## Usage

**Example:**

``` matlab
S3_Linearize
```

## Parameters

-   `linearization_window`: number of points used for local fitting\
-   `half_window`: half-size of the fitting window

## Dependencies

-   Required toolboxes:\
    MATLAB base environment (graphics, file I/O, polyfit)\
-   External functions/files:\
    None

## Notes

Structured grid assumption. Processing is performed column-wise along y.
Curvature is computed as a discrete derivative of slope. Output folders
are created if missing.

## Revision History

-   v1.0 (11-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
