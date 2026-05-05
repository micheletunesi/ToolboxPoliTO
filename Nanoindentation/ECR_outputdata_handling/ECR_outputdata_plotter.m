%% =========================
%  General Info
%  =========================
%  Filename: ECR_outputdata_plotter.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 05-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script processes all MAT files stored in the "output_files" folder.
%  For each file, it loads the variables "time_select" and "current_select",
%  computes the average current within a selected time window, generates an
%  individual plot, and saves the plot in PNG and MATLAB FIG formats.
%  The script also creates a summary table and a summary plot containing the
%  average current values for all processed files.
%
%  Inputs:
%  - time_select (numeric vector, N x 1 or 1 x N): time values loaded from each MAT file
%  - current_select (numeric vector, N x 1 or 1 x N): current values loaded from each MAT file
%
%  Outputs:
%  - resultsTable (table, M x 3): table containing file names, average current values,
%    and processing status
%  - individual PNG figures (image files): plots saved in ./output_files/figures
%  - individual FIG figures (MATLAB figure files): plots saved in ./output_files/plots
%  - summary_average_current.png (image file): summary plot saved in ./output_files/figures
%  - summary_average_current.fig (MATLAB figure file): summary plot saved in ./output_files/plots

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script from the MATLAB Command Window after placing the MAT files
%  inside the "output_files" folder:
%
%  average_current_batch_processing

%% =========================
%  Parameters
%  =========================
%  - outputDir: path to the folder containing the MAT files
%  - figPngDir: path to the folder where PNG figures are saved
%  - figDir: path to the folder where MATLAB FIG files are saved
%  - tStartAvg: start time of the averaging interval, in seconds
%  - tEndAvg: end time of the averaging interval, in seconds

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    None
%  - External functions/files:
%    MAT files stored in ./output_files, each containing "time_select" and
%    "current_select"

%% =========================
%  Notes
%  =========================
%  Files are skipped when required variables are missing, when data vectors
%  are empty, or when "time_select" and "current_select" have different
%  lengths. If no samples are found within the selected averaging interval,
%  the corresponding average value remains NaN.
%
%  The summary table is displayed in the Command Window. Optional save
%  commands for exporting the table as MAT or CSV are included at the end of
%  the script and can be uncommented.

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

clear;
clc;
close all;

%% Configuration

% Main folder containing MAT files
outputDir = fullfile(pwd, 'output_files');

% Output folders for saved figures
figPngDir = fullfile(outputDir, 'figures');
figDir    = fullfile(outputDir, 'plots');

% Averaging window in seconds
tStartAvg = 31;
tEndAvg   = 40;

%% Validate input folder and create output folders

if ~exist(outputDir, 'dir')
    error('The folder "output_files" does not exist in the current directory.');
end

if ~exist(figPngDir, 'dir')
    mkdir(figPngDir);
end

if ~exist(figDir, 'dir')
    mkdir(figDir);
end

%% Collect MAT files

fileList = dir(fullfile(outputDir, '*.mat'));

if isempty(fileList)
    error('No MAT files were found in "output_files".');
end

% Sort files alphabetically for reproducible processing order
[~, sortIdx] = sort({fileList.name});
fileList = fileList(sortIdx);

%% Preallocate result arrays

numFiles = numel(fileList);
fileNames = strings(numFiles, 1);
avgCurrent = nan(numFiles, 1);
isProcessed = false(numFiles, 1);

%% Process each file

for k = 1:numFiles
    thisFile = fileList(k).name;
    thisPath = fullfile(outputDir, thisFile);
    [~, baseName, ~] = fileparts(thisFile);

    fileNames(k) = string(baseName);

    fprintf('Processing file %d of %d: %s\n', k, numFiles, thisFile);

    % Load file content
    S = load(thisPath);

    % Validate required variables
    if ~isfield(S, 'time_select') || ~isfield(S, 'current_select')
        warning('Skipping "%s": missing "time_select" or "current_select".', thisFile);
        continue;
    end

    % Convert to column vectors for consistent handling
    time_select = S.time_select(:);
    current_select = S.current_select(:);

    % Validate data dimensions
    if numel(time_select) ~= numel(current_select)
        warning('Skipping "%s": "time_select" and "current_select" have different lengths.', thisFile);
        continue;
    end

    % Validate non-empty data
    if isempty(time_select)
        warning('Skipping "%s": data vectors are empty.', thisFile);
        continue;
    end

    % Identify samples inside the averaging interval
    idxAvg = (time_select >= tStartAvg) & (time_select <= tEndAvg);

    if any(idxAvg)
        avgCurrent(k) = mean(current_select(idxAvg), 'omitnan');
        isProcessed(k) = true;
    else
        warning('No data found between %.1f s and %.1f s in "%s".', ...
            tStartAvg, tEndAvg, thisFile);
    end

    % Create and save figure for this file
    hFig = createSingleFilePlot(time_select, current_select, idxAvg, ...
        tStartAvg, tEndAvg, avgCurrent(k), baseName);

    saveas(hFig, fullfile(figPngDir, [baseName, '.png']));
    savefig(hFig, fullfile(figDir, [baseName, '.fig']));

    close(hFig);
end

%% Create results table

resultsTable = table(fileNames, avgCurrent, isProcessed, ...
    'VariableNames', {'FileName', 'AverageCurrent_31_40s', 'ProcessedSuccessfully'});

disp(resultsTable);

%% Optional: save results table
% Uncomment these lines if you want to save the summary table
%
% save(fullfile(outputDir, 'average_current_35_55s.mat'), 'resultsTable');
% writetable(resultsTable, fullfile(outputDir, 'average_current_35_55s.csv'));

%% Create summary plot

validIdx = ~isnan(avgCurrent);

hSummary = figure('Name', 'Summary Average Current', 'Color', 'w');
plot(find(validIdx), avgCurrent(validIdx), 'o-', 'LineWidth', 1.2, 'MarkerSize', 6);
grid on;

xlabel('File index');
ylabel(sprintf('Average current from %.0f s to %.0f s', tStartAvg, tEndAvg));
title('Average current for all processed files');

xticks(find(validIdx));
xticklabels(fileNames(validIdx));
xtickangle(45);

saveas(hSummary, fullfile(figPngDir, 'summary_average_current.png'));
savefig(hSummary, fullfile(figDir, 'summary_average_current.fig'));

%% Final messages

disp(['PNG figures saved in: ', figPngDir]);
disp(['FIG files saved in: ', figDir]);
disp('Summary table displayed in the Command Window.');

%% Local function: single-file plot
function hFig = createSingleFilePlot(time_select, current_select, idxAvg, ...
    tStartAvg, tEndAvg, avgValue, baseName)
% createSingleFilePlot
% Create one figure showing:
%   - the full current signal
%   - the averaging interval limits
%   - the points used in the average
%   - the average value as a horizontal line

    hFig = figure('Visible', 'off', 'Color', 'w', 'Name', baseName);

    plot(time_select, current_select, 'b-', 'LineWidth', 1.2);
    hold on;
    grid on;

    % Plot averaging window limits
    xline(tStartAvg, '--k', 'LineWidth', 1.2);
    xline(tEndAvg, '--k', 'LineWidth', 1.2);

    % Highlight selected samples and plot mean value
    if any(idxAvg)
        plot(time_select(idxAvg), current_select(idxAvg), 'r.', 'MarkerSize', 10);
        plot([tStartAvg, tEndAvg], [avgValue, avgValue], 'm-', 'LineWidth', 2);
    end

    xlabel('Time (s)');
    ylabel('Current');
    title(baseName, 'Interpreter', 'none');

    if any(idxAvg)
        legend('Current', ...
               'Start of averaging window', ...
               'End of averaging window', ...
               'Data used for average', ...
               sprintf('Average current = %.6g', avgValue), ...
               'Location', 'best');
    else
        legend('Current', ...
               'Start of averaging window', ...
               'End of averaging window', ...
               'Location', 'best');
    end

    hold off;
end