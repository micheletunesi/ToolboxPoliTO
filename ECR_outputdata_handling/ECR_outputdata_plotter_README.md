## General Info

**Filename:** `ECR_outputdata_plotter.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 05-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
This script processes all MAT files stored in the "output_files" folder. For each file, it loads the variables "time_select" and "current_select", computes the average current within a selected time window, generates an individual plot, and saves the plot in PNG and MATLAB FIG formats. A summary table and a summary plot are also generated across all processed files.

**Inputs:**\
- `time_select` (numeric vector, N x 1 or 1 x N): time values loaded from each MAT file\
- `current_select` (numeric vector, N x 1 or 1 x N): current values loaded from each MAT file

**Outputs:**\
- `resultsTable` (table, M x 3): table containing file names, average current values, and processing status\
- PNG figures (files): saved in `./output_files/figures`\
- FIG figures (MATLAB files): saved in `./output_files/plots`\
- Summary plot (PNG and FIG): average current across all processed files

## Usage

**Example:**

```matlab
average_current_batch_processing
```

## Parameters

- `outputDir`: path to the folder containing MAT files\
- `figPngDir`: path to the folder where PNG figures are saved\
- `figDir`: path to the folder where MATLAB FIG files are saved\
- `tStartAvg`: start time of the averaging interval, in seconds\
- `tEndAvg`: end time of the averaging interval, in seconds

## Dependencies

- Required toolboxes:\
  None\
- External functions/files:\
  MAT files in `./output_files` containing `time_select` and `current_select`

## Notes

Files are skipped when required variables are missing, when data vectors are empty, or when input vectors have different lengths. If no samples are found within the selected averaging interval, the corresponding average value is set to NaN.

The summary table is displayed in the Command Window. Optional commands for saving the table as MAT or CSV are available in the script.

## Revision History

- v1.0 (05-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
