## General Info

**Filename:** `NanoAP_NanoCurve_Converter.m`  
**Creator:** Michele Tunesi  
**Email:** michele.tunesi@polito.it  
**Date:** 11-05-2026  
**Version:** 1.1

## Code Description

**Abstract:**  
Batch processing script for NanoAP indentation `.txt` files. The script extracts numeric data from the `Measured values` section, parses time, depth, and force columns, and saves each dataset as a `.mat` file. A curve image is saved for each processed file. An optional preview of force vs depth is displayed during processing.

**Inputs:**  
- `folderPath` (string, scalar): directory selected via GUI containing `.txt` files
- `showPreview` (logical, scalar): flag to enable or disable plotting preview

**Outputs:**  
- `.mat` files: time, depth, and force vectors saved in the `Processed` subfolder
- `.png` files: force vs depth curve images saved in the `Processed` subfolder

## Usage

**Example:**

Run the script in MATLAB and follow the prompts:

NanoAP_NanoCurve_Converter

The script asks whether to display preview figures and then opens a GUI folder selector for the directory containing the `.txt` files.

## Parameters

- `numericRowPattern`: regular expression used to detect numeric data rows
- `pause duration`: fixed at 3 s for preview display
- `output naming`: original `.txt` filename with `.mat` and `.png` extensions

## Dependencies

- Required toolboxes: none
- External functions/files: indentation curves in `.txt` format from Anton Paar software

## Notes

The script assumes fixed column ordering:

- column 1 = time
- column 2 = depth, in nm
- column 3 = force, in mN

Decimal commas are converted to decimal points before parsing. Files without a `Measured values` section or valid numeric data are skipped. Output files are saved as `<original_txt_filename>.mat`, not `.txt.mat`. Curve images are always saved, also when preview display is disabled.

## Revision History

- v1.0 (07-05-2026): initial version
- v1.1 (11-05-2026): removed base filename prompt, saved `.mat` files using original `.txt` filenames, and added figure saving

## License

This work is licensed under the Creative Commons  
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).  
You are free to reuse and adapt this code for non-commercial purposes,  
provided that appropriate credit is given to the original author.  
License details: https://creativecommons.org/licenses/by-nc/4.0/
