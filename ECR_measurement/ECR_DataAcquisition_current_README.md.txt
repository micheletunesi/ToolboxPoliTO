# ECR_DataAcquisition_current

## Overview
This script performs DC current acquisition from a Fluke 8845A multimeter over a TCP/IP connection using SCPI commands. It provides real-time visualization, moving-mean filtering, periodic autosave, and configurable final data export.

The workflow is designed for long-duration measurements with continuous monitoring and partial data persistence.

## Features
- TCP/IP communication with Fluke 8845A
- Configurable acquisition duration
- Block acquisition using `:READ?` and `SAMP:COUN`
- Live plot of the most recent time window
- Moving-mean computation on live data
- Filtering of invalid or overload values
- Periodic autosave of recent data segments
- Optional final save in compact or full format
- Automatic instrument reset on exit

## Requirements
- MATLAB with `tcpclient` support
- Fluke 8845A with TCP/IP interface enabled
- Network connection to the instrument

## Configuration

All parameters are defined in the **USER SETTINGS** section of the script.

### Acquisition
- `timeInMinutes`: total duration of the test
- `sampleCount`: number of samples per read operation
- `liveWindow_s`: width of the live plot window
- `movMeanWindowSamples`: moving-mean window length

### Instrument
- `ipAddress`: instrument IP address
- `portNumber`: TCP port (default: 3490)
- `timeout_s`: communication timeout

### Measurement
- `currentRange_A`: fixed current range
- `setFixedRange`: enable or disable fixed range
- `nplcValue`: integration time in power line cycles
- `useAutoZero`: auto-zero setting

### Autosave
- `autosaveEnabled`: enable autosave
- `autosaveEvery_s`: autosave interval
- `autosaveWindow_s`: duration of saved window
- `autosaveFolder`: output directory

### Output
- `defaultFilePrefix`: default filename prefix
- `cleanSaveDefault`: default save mode

## Execution
Run the script directly in MATLAB. The acquisition starts immediately after initialization.

- A figure window displays live current data in mA
- Press any key in the figure window to stop acquisition early
- Closing the figure also stops execution

## Data Handling

### Live Data
Only valid samples are used for plotting:
- Finite values
- Absolute value below `overloadThreshold_mA`

### Autosave Files
Autosave files are written periodically in `.mat` format and contain:
- `tA`: time vector of the last window
- `dA`: current vector of the last window

The first autosave file includes the suffix `_start`.

### Final Save

At the end of the acquisition, the user is prompted to save data.

#### Compact Save
- `time`: valid time vector [s]
- `current`: valid current vector [mA]

#### Full Save
- `AllData`: full dataset `[time, current]`
- `Res`: structure with block-level data
- `rawCurrent`: raw SCPI responses
- `timeValid`: filtered time vector
- `ResValid`: filtered current vector

## Data Structure

### Res structure
Each element corresponds to one acquisition block:
- `tstart`: block start time [s]
- `tstop`: block end time [s]
- `R`: current values [mA]
- `timeArr`: timestamps associated with samples

## Notes
- Time vectors are reconstructed assuming uniform sampling within each read block
- Autosave extracts the last valid window from accumulated data
- Cleanup is handled using `onCleanup` to restore instrument local control

## Limitations
- No hardware triggering support
- Timing accuracy depends on MATLAB execution and network latency
- Large datasets may lead to memory growth due to dynamic array expansion

## License
Specify the license used in your repository.

## Author
Specify author name and affiliation if required.