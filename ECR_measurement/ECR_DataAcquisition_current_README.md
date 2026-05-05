## General Info

**Filename:** `ECR_DataAcquisition_current.m`\
**Creator:** Michele Tunesi\
**Email:** michele.tunesi@polito.it\
**Date:** 05-05-2026\
**Version:** 1.0

## Code Description

**Abstract:**\
This script acquires DC current data from a Fluke 8845A multimeter over TCP/IP using SCPI commands. Data are collected in blocks, converted to mA, filtered for invalid values, and visualized in a live plot with a moving-mean trace. The script includes autosave functionality and supports final export in compact or full format.

**Inputs:**\
- `ipAddress` (char, 1xN): instrument IP address\
- `portNumber` (scalar): TCP port\
- `timeInMinutes` (scalar): acquisition duration\
- `sampleCount` (scalar): samples per acquisition block\
- `currentRange_A` (scalar): fixed current range\
- `nplcValue` (scalar): integration time

**Outputs:**\
- `time` (Nx1): valid time vector [s]\
- `current` (Nx1): valid current vector [mA]\
- `AllData` (Nx2): full dataset [time, current]\
- `Res` (struct): block data\
- `rawCurrent` (string array): raw SCPI responses\
- `timeValid` (Nx1): filtered time\
- `ResValid` (Nx1): filtered current

## Usage

**Example:**

```matlab
ECR_DataAcquisition_current
```

## Parameters

- `timeInMinutes`: acquisition duration\
- `sampleCount`: samples per read\
- `liveWindow_s`: live plot window\
- `movMeanWindowSamples`: moving mean length\
- `autosaveEnabled`: enable autosave\
- `autosaveEvery_s`: autosave interval\
- `autosaveWindow_s`: autosave window\
- `autosaveFolder`: autosave directory\
- `ipAddress`: instrument IP\
- `portNumber`: TCP port\
- `timeout_s`: timeout\
- `currentRange_A`: current range\
- `setFixedRange`: fixed range selection\
- `nplcValue`: integration time\
- `useAutoZero`: auto-zero control\
- `plotRefresh_s`: plot update period\
- `overloadThreshold_mA`: validity threshold\
- `defaultFilePrefix`: output filename prefix\
- `cleanSaveDefault`: default save mode

## Dependencies

- Required toolboxes:\
  Instrument Control Toolbox or tcpclient support\
- External functions/files:\
  Fluke 8845A over TCP/IP

## Notes

The script stops after the selected duration or when a key is pressed in the figure window. Invalid values are filtered using a threshold. The instrument is returned to local mode on exit using a cleanup routine.

## Revision History

- v1.0 (05-05-2026): initial version

## License

This work is licensed under the Creative Commons\
Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).\
You are free to reuse and adapt this code for non-commercial purposes,\
provided that appropriate credit is given to the original author.\
License details: https://creativecommons.org/licenses/by-nc/4.0/
