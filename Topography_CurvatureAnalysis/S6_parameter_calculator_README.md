# S6 Parameter Calculator

## General Info

**Filename:** `S6_parameter_calculator.m`  
**Creator:** Michele Tunesi  
**Email:** michele.tunesi@polito.it  
**Date:** 18-05-2026  
**Version:** 2.0

---

## Code Description

### Abstract

This MATLAB script processes multiple `.mat` files containing minima coordinate data generated in previous processing stages. The script automatically computes the maximum distance between two point sets (`sx` and `dx`) and provides an optional manual correction workflow through graphical point selection.

For each processed file, the selected distance, selected points, and measurement method are stored in the updated data structure and exported to Excel together with figure outputs.

### Inputs

- `*.mat` files (struct): MATLAB files containing the variable `data`
- `data.minima_calc.sx` (`Nx1 double`): left minima coordinates
- `data.minima_calc.dx` (`Nx1 double`): right minima coordinates

### Outputs

- Updated `.mat` files containing:
  - `data.size_pts` (`2x2 double`): selected points
  - `data.size` (`1x1 double`): measured distance
  - `data.size_method` (`char`): `"auto"` or `"manual"`

- `.png` figures showing accepted measurements

- `.fig` MATLAB figure files

- `Distances_manual.xlsx` containing:
  - filename
  - measured distance
  - measurement method

---

## Usage

### Example

Run the script directly from MATLAB:

```matlab
S6_parameter_calculator
```

### Required Folder Structure

```text
./S4_Minima_NA_calculation/
./S6_parameter_calculator/
```

The script automatically:
- reads `.mat` files from `S4_Minima_NA_calculation`
- creates outputs inside `S6_parameter_calculator`

---

## Workflow

### 1. Automatic Distance Estimation

The script computes the maximum Euclidean distance between all points belonging to:
- `sx`
- `dx`

The automatic result is displayed graphically.

### 2. User Validation

The user can:
- press `Enter` to accept the automatic result
- press `Spacebar` to manually select two points
- press `ESC` to stop execution

### 3. Manual Mode

If manual mode is selected:
1. the user clicks two points
2. each click is snapped to the nearest plotted coordinate
3. the distance is computed
4. a confirmation dialog appears:
   - `Save`
   - `Start over`

### 4. Export

For each processed dataset, the script saves:
- updated `.mat`
- `.png`
- `.fig`
- Excel row with:
  - filename
  - distance
  - method

---

## Parameters

- `folder_source`: input folder containing `.mat` files
- `folder_output`: output folder for processed results
- `dist_auto`: automatically calculated maximum distance
- `dist_manual`: manually selected distance
- `method_val`: accepted measurement mode (`"auto"` or `"manual"`)

---

## Dependencies

### Required Toolboxes

- MATLAB base environment

### External Functions/Files

- None

---

## Local Functions

### `find_max_distance_between_sets`

Computes the maximum distance between the `sx` and `dx` point sets.

### `wait_for_enter_space_or_esc`

Handles keyboard interaction:
- `Enter`
- `Spacebar`
- `ESC`

Mouse clicks and unrelated keys are ignored.

### `get_snapped_point`

Snaps a user click to the nearest plotted coordinate.

### `plot_base_points`

Displays minima points without measurement overlays.

### `plot_current_result`

Displays the accepted measurement and selected points.

### `format_axes`

Applies common axis formatting.

---

## Notes

- The automatic distance calculation avoids allocation of a full `NxN` distance matrix to reduce memory usage.
- Manual point selection uses nearest-neighbor snapping.
- Existing Excel output files are overwritten at each execution.
- Processing status messages are displayed throughout execution.
- Figures are exported at `300 dpi`.

### Keyboard Controls

| Key | Action |
|---|---|
| Enter | Accept automatic distance |
| Spacebar | Open manual mode |
| ESC | Stop execution |

---

## Revision History

- v1.0 (13-02-2026): initial version
- v2.0 (18-05-2026): added automatic distance calculation and refined manual distance calculation procedure

---

## License

This work is licensed under the Creative Commons  
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).  

You are free to reuse and adapt this code for non-commercial purposes,  
provided that appropriate credit is given to the original author.  

License details:  
https://creativecommons.org/licenses/by-nc/4.0/
