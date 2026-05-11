## General Info

**Filename:** `S1_Data_conversion_PoliTO.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 11-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
This script converts raw point cloud data exported from Sensofar
software (PoliTO optical measurements) into structured grid format. The
output is a MATLAB structure with gridded x, y, z data and corresponding
visualization plots.

**Inputs:**\
- `.txt` files (numeric, n×3): columns represent x, y, z coordinates
from Sensofar export\

**Outputs:**\
- `data` (struct): containing data.active.x, data.active.y,
data.active.z (m×n grids)\
- `.mat` files: processed data saved using -v7.3 format\
- `.png` files: surface plots of the data

## Usage

**Example:**

``` matlab
S1_Data_Preparation
```

## Parameters

-   `downsample_factor`: subsampling factor for plotting\
-   `folder_source`: directory containing raw data\
-   `folder_output`: directory for processed data\
-   `folder_output2`: directory for plots

## Dependencies

-   Required toolboxes:\
    MATLAB base environment (graphics, file I/O)\
-   External functions/files:\
    None

## Notes

This code is specifically designed for PoliTO data exported from
Sensofar software. It assumes the raw data is ordered and can be
reshaped into a structured grid without interpolation. The script uses
reshape for performance and saves data using -v7.3 for large datasets.

## Revision History

-   v1.0 (11-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
