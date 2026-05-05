%% =========================
%  General Info
%  =========================
%  Filename: ECR_DataAcquisition_current.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 05-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script acquires DC current data from a Fluke 8845A multimeter over a
%  TCP/IP connection using SCPI commands. The instrument is configured for
%  DC current measurements, and data are acquired in blocks, converted to
%  mA, filtered for invalid or overload values, and displayed in a live
%  plot. The live plot shows the most recent time window together with a
%  moving-mean trace. The script also supports periodic autosave and an
%  optional final export in compact or full format.
%
%  Inputs:
%  - ipAddress (character vector, 1 x N): Fluke 8845A IP address
%  - portNumber (numeric scalar): TCP port used for communication
%  - timeInMinutes (numeric scalar): total acquisition duration in minutes
%  - sampleCount (numeric scalar): number of samples returned by each READ command
%  - currentRange_A (numeric scalar): fixed DC current range in A
%  - nplcValue (numeric scalar): integration time in power line cycles
%
%  Outputs:
%  - time (numeric vector, N x 1): valid acquisition time vector in s, compact save
%  - current (numeric vector, N x 1): valid current vector in mA, compact save
%  - AllData (numeric matrix, N x 2): full dataset containing time in s and current in mA
%  - Res (structure array, 1 x M): block-wise acquisition data
%  - rawCurrent (string vector, M x 1): raw SCPI replies
%  - timeValid (numeric vector, N x 1): valid acquisition time vector in s
%  - ResValid (numeric vector, N x 1): valid current vector in mA

%% =========================
%  Usage
%  =========================
%  Example:
%  ECR_DataAcquisition_current

%% =========================
%  Parameters
%  =========================
%  - timeInMinutes: total acquisition duration in minutes
%  - sampleCount: number of samples requested from the instrument at each read
%  - liveWindow_s: width of the live plot time window in s
%  - movMeanWindowSamples: moving-mean window length in samples
%  - autosaveEnabled: enable or disable periodic autosave
%  - autosaveEvery_s: autosave period in s
%  - autosaveWindow_s: length of the recent data window saved during autosave
%  - autosaveFolder: folder used for autosave MAT files
%  - ipAddress: Fluke 8845A IP address
%  - portNumber: TCP communication port
%  - timeout_s: TCP communication timeout in s
%  - currentRange_A: fixed DC current range in A
%  - setFixedRange: select fixed current range or default instrument range
%  - nplcValue: integration time in power line cycles
%  - useAutoZero: enable or disable auto-zero
%  - plotRefresh_s: live plot update period in s
%  - overloadThreshold_mA: absolute threshold used to reject invalid current values
%  - defaultFilePrefix: default prefix used for final save filenames
%  - cleanSaveDefault: default setting for compact or full final export

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    Instrument Control Toolbox or MATLAB support for tcpclient
%  - External functions/files:
%    Fluke 8845A multimeter reachable over TCP/IP

%% =========================
%  Notes
%  =========================
%  The script stops automatically after the selected acquisition duration.
%  It can also be stopped early by pressing a key in the figure window or by
%  closing the figure. Invalid, non-finite, or overload values are removed
%  from the live plot and from the valid saved vectors according to
%  overloadThreshold_mA.
%
%  The onCleanup object calls localCleanup when the script exits, so the
%  instrument is returned to local control also after an interruption or an
%  execution error.

%% =========================
%  Revision History
%  =========================
%  v1.0 (05-05-2026): initial version

%% =========================
%  License
%  =========================
%  This work is licensed under the Creative Commons
%  Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
%  You are free to reuse and adapt this code for non-commercial purposes,
%  provided that appropriate credit is given to the original author.
%  License details: https://creativecommons.org/licenses/by-nc/4.0/

clearvars
close all
clc

%% FLUKE 8845A DC CURRENT ACQUISITION WITH LIVE WINDOW (LAST 90 s) [mA]

%% USER SETTINGS

% Acquisition timing
timeInMinutes        = 55;      % Total acquisition duration [min]
sampleCount          = 20;      % Samples returned by each :READ? command
liveWindow_s         = 90;      % Width of the live plot window [s]
movMeanWindowSamples = 20;      % Moving-mean window length [samples]

% Autosave
autosaveEnabled      = true;    % Enable periodic autosave
autosaveEvery_s      = 30;      % Autosave period [s]
autosaveWindow_s     = 30;      % Length of exported recent window [s]
autosaveFolder       = 'autosave'; % Folder used for autosave files

% Instrument connection
ipAddress            = '169.254.1.1'; % Fluke 8845A IP address
portNumber           = 3490;          % TCP port
timeout_s            = 10;            % Communication timeout [s]

% Current measurement setup
currentRange_A       = 1e-2;    % Fixed DC current range [A]
setFixedRange        = true;    % true: use currentRange_A, false: instrument default
nplcValue            = 1;       % Integration time in power line cycles
useAutoZero          = false;   % true: auto-zero enabled

% Live plot refresh
plotRefresh_s        = 1.0;     % Plot update period [s]

% Data filtering
overloadThreshold_mA = 1e30;    % Absolute threshold used to reject invalid values [mA]

% Save
defaultFilePrefix    = 'Al46000_secondario'; % Default prefix for final save

% Cleanup
% If true: save only time + current
% If false: save full dataset
cleanSaveDefault     = true;

%% DERIVED PARAMETERS

% Total acquisition duration converted to seconds
timeOfTest_s = timeInMinutes * 60;

%% INITIALIZATION

% Structure array used to store each acquisition block
Res = struct('R', {}, 'tstart', {}, 'tstop', {}, 'timeArr', {});

% Raw replies returned by the instrument
rawCurrent = strings(0,1);

% Vectors used for live plotting
timeAllLive = [];
ResAllLive  = [];

% Acquisition state counters
acqIndex = 1;
lastPlotUpdate = 0;

% Autosave state
autosaveCount = 0;
nextAutosaveTime = autosaveEvery_s;

% Create autosave folder if required
if autosaveEnabled && ~exist(autosaveFolder, 'dir')
    mkdir(autosaveFolder);
end

%% CONNECTION

try
    t = tcpclient(ipAddress, portNumber, "Timeout", timeout_s);
    disp('TCP connection setup.')
catch ME
    error('TCP connection failed: %s', ME.message);
end

% Register cleanup so the instrument returns to local mode on exit
cleanupObj = onCleanup(@() localCleanup(t)); %#ok<NASGU>

%% CONFIGURATION

% Clear status and switch the instrument to remote mode
writeline(t, "*CLS");
writeline(t, "SYST:REM");

% Configure DC current measurement, optionally with fixed range
if setFixedRange
    writeline(t, sprintf("CONF:CURR:DC %.12g", currentRange_A));
else
    writeline(t, "CONF:CURR:DC");
end

% Set integration time
writeline(t, sprintf("CURR:DC:NPLC %.12g", nplcValue));

% Configure auto-zero
if useAutoZero
    writeline(t, "ZERO:AUTO 1");
else
    writeline(t, "ZERO:AUTO 0");
end

% Configure trigger and sample count
writeline(t, "TRIG:SOUR IMM");
writeline(t, "TRIG:DEL 0");
writeline(t, "TRIG:COUN 1");
writeline(t, sprintf("SAMP:COUN %d", sampleCount));

%% FIGURE

% Create figure for live visualization
f = figure('Name', sprintf('Live current acquisition (last %.0f s)', liveWindow_s), ...
    'Color', 'w', 'Units', 'normalized', 'Position', [0.2 0.15 0.6 0.65]);

% CurrentCharacter is used to detect keyboard interruption
set(f, 'CurrentCharacter', char(0));

% Create axes
ax = axes(f, 'Position', [0.10 0.15 0.85 0.75]);
hold(ax, 'on');
grid(ax, 'on');
box(ax, 'on');

xlabel(ax, 'Time [s]')
ylabel(ax, 'Current [mA]')
title(ax, 'Live DC current acquisition')

% Raw live trace
hRaw = plot(ax, nan, nan, '-');

% Moving-mean live trace
hMov = plot(ax, nan, nan, '-', 'LineWidth', 2);

%% ACQUISITION LOOP

disp('Acquisition started.')
disp('Press any key in the figure window to stop early.')

tic
timeFin = 0;

while timeFin < timeOfTest_s

    % Stop if the figure has been closed
    if ~isgraphics(f)
        break;
    end

    % Stop if any key has been pressed in the figure window
    if double(get(f, 'CurrentCharacter')) ~= 0
        disp('Stopped by user')
        break;
    end

    % Acquisition start time of the current read block
    timeStart = toc;

    % Read one measurement block from the instrument
    rawReply = strtrim(writeread(t, ":READ?"));

    % Acquisition stop time of the current read block
    timeFin = toc;

    % Store raw reply
    rawCurrent(acqIndex, 1) = string(rawReply);

    % Convert SCPI comma-separated values to numeric current data in mA
    parts  = split(rawReply, ',');
    values = str2double(parts);
    values = values(:) * 1e3;

    % Reconstruct sample timestamps across the read interval
    if numel(values) == 1
        timeArr = timeFin;
    else
        timeArr = linspace(timeStart, timeFin, numel(values)).';
    end

    % Store block data
    Res(acqIndex).tstart  = timeStart;
    Res(acqIndex).tstop   = timeFin;
    Res(acqIndex).R       = values;
    Res(acqIndex).timeArr = timeArr;

    % Keep only finite values below the overload threshold
    valid = isfinite(values) & abs(values) < overloadThreshold_mA;

    % Append valid data to live buffers
    timeAllLive = [timeAllLive; timeArr(valid)]; %#ok<AGROW>
    ResAllLive  = [ResAllLive; values(valid)];   %#ok<AGROW>

    %% LIVE WINDOW

    % Retain only the data belonging to the last liveWindow_s seconds
    if ~isempty(timeAllLive)
        tMax = timeAllLive(end);
        keep = timeAllLive >= (tMax - liveWindow_s);
        timeAllLive = timeAllLive(keep);
        ResAllLive  = ResAllLive(keep);
    end

    %% AUTOSAVE

    if autosaveEnabled
        while timeFin >= nextAutosaveTime
            autosaveCount = autosaveCount + 1;

            % Extract the most recent autosave window from the accumulated data
            [tA, dA] = extractLastWindow(Res, autosaveWindow_s, overloadThreshold_mA);

            % Timestamp used in autosave filename
            tsAutosave = datetime('now', 'Format', 'yyyyMMdd_HHmmss');

            if autosaveCount == 1
                fname = char(tsAutosave) + "_start.mat";
            else
                fname = char(tsAutosave) + ".mat";
            end

            save(fullfile(autosaveFolder, fname), 'tA', 'dA')

            % Move autosave target to the next period
            nextAutosaveTime = nextAutosaveTime + autosaveEvery_s;
        end
    end

    %% LIVE PLOT UPDATE

    if (timeFin - lastPlotUpdate >= plotRefresh_s) || acqIndex == 1

        % Update raw trace
        set(hRaw, 'XData', timeAllLive, 'YData', ResAllLive)

        % Update moving-mean trace only when enough samples are available
        if numel(ResAllLive) >= movMeanWindowSamples
            set(hMov, 'XData', timeAllLive, ...
                'YData', movmean(ResAllLive, movMeanWindowSamples))
        else
            set(hMov, 'XData', nan, 'YData', nan)
        end

        % Update axis limits based on current live window
        if ~isempty(timeAllLive)
            xlim(ax, [timeAllLive(1), timeAllLive(end)])

            yMin = min(ResAllLive);
            yMax = max(ResAllLive);

            if yMin ~= yMax
                pad = 0.05 * (yMax - yMin);
            else
                pad = max(1e-6, 0.05 * abs(yMin));
            end

            ylim(ax, [yMin - pad, yMax + pad])
        end

        title(ax, sprintf('Last %.0f s | Elapsed %.1f s', liveWindow_s, timeFin))

        drawnow limitrate
        lastPlotUpdate = timeFin;
    end

    % Increment acquisition block index
    acqIndex = acqIndex + 1;
end

%% FINAL DATA ASSEMBLY

% Concatenate all acquired blocks into full vectors
timeAll = [];
ResAll  = [];

for k = 1:numel(Res)
    if isempty(Res(k).R)
        continue
    end

    timeAll = [timeAll; Res(k).timeArr(:)]; %#ok<AGROW>
    ResAll  = [ResAll; Res(k).R(:)];        %#ok<AGROW>
end

% Combined matrix for full export
AllData = [timeAll, ResAll];

% Build valid vectors using the overload filter
valid     = isfinite(ResAll) & abs(ResAll) < overloadThreshold_mA;
timeValid = timeAll(valid);
ResValid  = ResAll(valid);

%% FINAL SAVE

choice = questdlg('Save data?', 'Save', 'Yes', 'No', 'Yes');

if strcmp(choice, 'Yes')

    % Default save mode
    cleanSave = cleanSaveDefault;

    % Ask whether only the compact dataset should be saved
    answer = questdlg('Save only time and current?', 'Clean save', 'Yes', 'No', 'No');

    if strcmp(answer, 'Yes')
        cleanSave = true;
    else
        cleanSave = false;
    end

    % Timestamp for final export default filename
    tsFinal = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));

    fname = inputdlg('Filename:', 'Save', 1, ...
        {sprintf('%s_%s', defaultFilePrefix, tsFinal)});

    if ~isempty(fname)
        filename = [fname{1} '.mat'];

        if cleanSave
            time = timeValid; %#ok<NASGU>
            current = ResValid; %#ok<NASGU>
            save(filename, 'time', 'current')
        else
            save(filename, 'AllData', 'Res', 'rawCurrent', 'timeValid', 'ResValid')
        end

        disp(['Saved: ' filename])
    end
end

%% RELEASE INSTRUMENT

try
    writeline(t, "DISP ON");
catch
end

try
    writeline(t, "TRIG:SOUR IMM");
catch
end

try
    writeline(t, "SAMP:COUN 1");
catch
end

try
    writeline(t, "SYST:LOC");
    pause(0.1);
catch
end

clear t

%% LOCAL FUNCTIONS

function localCleanup(t)
% Return the instrument to a basic local state when the script exits.
    try
        writeline(t, "DISP ON");
    catch
    end

    try
        writeline(t, "TRIG:SOUR IMM");
    catch
    end

    try
        writeline(t, "SAMP:COUN 1");
    catch
    end

    try
        writeline(t, "SYST:LOC");
        pause(0.1);
    catch
    end
end

function [tW, dW] = extractLastWindow(Res, win, thr)
% Extract the last time window of valid data from the block structure.
%
% Inputs
% - Res: structure array containing acquired blocks
% - win: window length [s]
% - thr: absolute validity threshold
%
% Outputs
% - tW: time vector in the selected recent window
% - dW: data vector in the selected recent window

    tAll = [];
    dAll = [];

    for k = 1:numel(Res)
        if isempty(Res(k).R)
            continue
        end

        tAll = [tAll; Res(k).timeArr(:)]; %#ok<AGROW>
        dAll = [dAll; Res(k).R(:)];       %#ok<AGROW>
    end

    % Keep only finite values below the threshold
    v = isfinite(dAll) & abs(dAll) < thr;
    tAll = tAll(v);
    dAll = dAll(v);

    % Return empty outputs if no valid data are available
    if isempty(tAll)
        tW = [];
        dW = [];
        return
    end

    % Select only the last window
    tMax = tAll(end);
    keep = tAll >= (tMax - win);
    tW = tAll(keep);
    dW = dAll(keep);
end