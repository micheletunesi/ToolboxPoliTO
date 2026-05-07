## General Info

**Filename:** `ECR_outputdata_cutter.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 07-05-2026\
**Version:** 1.01

## Code Description

**Abstract:**\
This script interactively loads a MAT-file containing time-current data,
allows the user to select a fixed-duration interval, estimates a linear
background from tail regions before and after the interval, subtracts
the background, and saves the processed signal together with the
original full signal.

**Inputs:**\
- User-selected MAT-file: must contain variable `AllData`\
- `AllData(:,1)` (Nx1 double): time vector, in seconds\
- `AllData(:,2)` (Nx1 double): current signal

**Outputs:**\
- `time_select` (Mx1 double): selected time vector shifted to start at
zero\
- `current_select` (Mx1 double): background-subtracted current signal\
- `time_full` (Nx1 double): original full time vector\
- `current_full` (Nx1 double): original full current signal\
- `timestamps` (1x2 double): original start and end times of the
selected interval\
- Output `.mat` file saved in `output_files` directory

## Usage

**Example:**

``` matlab
% Run the script
% Select a MAT-file when prompted
% Select two points for zoom region
% Select final point defining interval end
% Enter output file number
```

## Parameters

-   `tailDuration`: duration of each tail region used for background
    fit, in seconds\
-   `mainDuration`: duration of the selected interval, in seconds\
-   `base_filename`: base name for saved output files\
-   `previewTime`: duration of background subtraction preview, in
    seconds\
-   `kk`: initial proposed file number

## Dependencies

-   Required toolboxes: none\
-   External functions/files: MAT-file containing variable `AllData`

## Notes

The selected interval is defined as a fixed-duration window ending at
the user-selected final point. Background subtraction is performed using
a first-order polynomial fit on the left and right tail regions. The
script operates in an interactive loop, allowing repeated processing or
restart. Press ESC to exit. Press ENTER to restart.

## Revision History

-   v1.0 (05-05-2026): initial version
-   v1.01 (07-05-2026): Fixed basename in downloadable code

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
