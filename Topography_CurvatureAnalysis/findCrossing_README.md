## General Info

**Filename:** `findCrossing.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 11-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
This function detects the first crossing of a signal through a specified
threshold. It supports forward or backward search and detects positive
or negative crossings, returning the last sample before the crossing or
the exact match.

**Inputs:**\
- `X` (numeric vector, n×1 or 1×n): coordinate vector\
- `Y` (numeric vector, n×1 or 1×n): signal vector\
- `crossingValue` (double scalar): threshold value\
- `direction` (char/string): 'forward' or 'backward'\
- `signDir` (char/string): 'positive' or 'negative'

**Outputs:**\
- `xCross` (double scalar): X coordinate of crossing\
- `yCross` (double scalar): Y value at crossing\
- `idxCross` (double scalar): index of crossing point

## Usage

**Example:**

``` matlab
[xCross, yCross, idxCross] = findCrossing(X, Y, 0.5, 'forward', 'positive');
```

## Parameters

-   `direction`: defines iteration order over the vector\
-   `signDir`: defines type of crossing (below-to-above or
    above-to-below)

## Dependencies

-   Required toolboxes:\
    MATLAB base environment\
-   External functions/files:\
    None

## Notes

NaN values are ignored. If no crossing is found, outputs are NaN. Exact
matches to the threshold are prioritized over bracket crossings.

## Revision History

-   v1.0 (11-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
