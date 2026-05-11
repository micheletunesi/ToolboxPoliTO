%% =========================
%  General Info
%  =========================
%  Filename: NanoAP_NanoCurve_Converter.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 11-05-2026
%  Version: 1.1

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  Batch processing script for NanoAP indentation .txt files. The script
%  extracts numeric data from the "Measured values" section, parses time,
%  depth, and force columns, and saves each dataset as a .mat file. A curve
%  image is saved for each processed file. An optional preview of force vs
%  depth is displayed during processing.
%
%  Inputs:
%  - folderPath (string, scalar): directory selected via GUI containing .txt files
%  - showPreview (logical, scalar): flag to enable or disable plotting preview
%
%  Outputs:
%  - .mat files (time, depth, force vectors): saved in "Processed" subfolder
%  - .png files: force vs depth curve images saved in "Processed" subfolder
%  - Output filenames match the original .txt filenames, with .mat and .png extensions

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script and follow prompts:
%  - Choose whether to display preview figures
%  - Select folder containing .txt files

%% =========================
%  Parameters
%  =========================
%  - numericRowPattern: regular expression used to detect numeric data rows
%  - pause duration: fixed at 3 s for preview display
%  - output naming: original .txt filename with .mat and .png extensions

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes: none
%  - External functions/files: Indentation curves in .txt format from Anton
%  Paar software

%% =========================
%  Notes
%  =========================
%  - The script assumes fixed column ordering:
%       column 1 = time
%       column 2 = depth (nm)
%       column 3 = force (mN)
%  - Decimal commas are converted to decimal points before parsing.
%  - Files without a "Measured values" section or valid numeric data are skipped.
%  - Output files are saved as <original_txt_filename>.mat, not .txt.mat.
%  - Curve images are always saved, also when preview display is disabled.

%% =========================
%  Revision History
%  =========================
%  v1.0 (07-05-2026): initial version
%  v1.1 (11-05-2026): removed base filename prompt and saved .mat files
%                     using original .txt filenames and added figure saving
%   

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

%% USER INPUTS
showPreview = input('Show preview figures? (true/false): ');

if isempty(showPreview)
    showPreview = true;
end

%% Select input folder
folderPath = uigetdir(pwd, 'Select folder containing indentation txt files');

if isequal(folderPath, 0)
    error('No folder selected.');
end

%% Find .txt files
fileList = dir(fullfile(folderPath, '*.txt'));

if isempty(fileList)
    error('No .txt files found in the selected folder.');
end

%% Create output folder
processedFolder = fullfile(folderPath, 'Processed');

if ~exist(processedFolder, 'dir')
    mkdir(processedFolder);
end

%% Create preview figure only if requested
if showPreview
    hFig = figure( ...
        'Name', 'Force vs Depth preview', ...
        'NumberTitle', 'off');
else
    hFig = [];
end

%% Initialize counters
nFiles = numel(fileList);
nSaved = 0;
nImagesSaved = 0;
nSkipped = 0;

%% Pattern used to identify numeric data rows
numericRowPattern = '^[-+]?\d*\.?\d+([eE][-+]?\d+)?(\s+|$)';

%% Process each file
for k = 1:nFiles

    fileName = fileList(k).name;
    inputFile = fullfile(folderPath, fileName);

    fprintf('\nProcessing %d/%d: %s\n', k, nFiles, fileName);

    %% Read file content
    rawText = fileread(inputFile);
    lines = regexp(rawText, '\r\n|\n|\r', 'split');

    %% Find "Measured values"
    idxMeasured = find(contains(lines, 'Measured values'), 1, 'first');

    if isempty(idxMeasured)
        warning('Skipping %s: "Measured values" not found.', fileName);
        nSkipped = nSkipped + 1;
        continue;
    end

    %% Find first numeric row
    startIdx = idxMeasured + 1;

    while startIdx <= numel(lines)

        thisLine = strtrim(lines{startIdx});
        thisLine = strrep(thisLine, ',', '.');

        if ~isempty(regexp(thisLine, numericRowPattern, 'once'))
            break;
        end

        startIdx = startIdx + 1;
    end

    if startIdx > numel(lines)
        warning('Skipping %s: numeric data not found.', fileName);
        nSkipped = nSkipped + 1;
        continue;
    end

    %% Collect numeric rows
    dataLines = lines(startIdx:end);
    isNumericRow = false(numel(dataLines), 1);

    for i = 1:numel(dataLines)

        thisLine = strtrim(dataLines{i});

        if isempty(thisLine)
            continue;
        end

        thisLine = strrep(thisLine, ',', '.');

        if ~isempty(regexp(thisLine, numericRowPattern, 'once'))
            isNumericRow(i) = true;
            dataLines{i} = thisLine;
        else
            dataLines = dataLines(1:i-1);
            isNumericRow = isNumericRow(1:i-1);
            break;
        end
    end

    dataLines = dataLines(isNumericRow);

    if isempty(dataLines)
        warning('Skipping %s: no numeric rows.', fileName);
        nSkipped = nSkipped + 1;
        continue;
    end

    %% Parse numeric rows
    parsedRows = cell(numel(dataLines), 1);
    nValidRows = 0;

    for i = 1:numel(dataLines)

        nums = sscanf(dataLines{i}, '%f').';

        if numel(nums) >= 3
            nValidRows = nValidRows + 1;
            parsedRows{nValidRows} = nums(1:3);
        end
    end

    if nValidRows == 0
        warning('Skipping %s: insufficient numeric columns.', fileName);
        nSkipped = nSkipped + 1;
        continue;
    end

    %% Convert to matrix
    parsedData = NaN(nValidRows, 3);

    for i = 1:nValidRows
        parsedData(i, :) = parsedRows{i};
    end

    %% Assign columns
    time  = parsedData(:, 1);
    depth = parsedData(:, 2);
    force = parsedData(:, 3);

    %% Define output filenames using original .txt filename
    [~, baseFileName, ~] = fileparts(fileName);

    outputMatName = sprintf('%s.mat', baseFileName);
    outputPngName = sprintf('%s.png', baseFileName);

    outputMatFile = fullfile(processedFolder, outputMatName);
    outputPngFile = fullfile(processedFolder, outputPngName);

    %% Save .mat file
    save(outputMatFile, 'time', 'depth', 'force');

    fprintf('Saved MAT: %s\n', outputMatFile);
    nSaved = nSaved + 1;

    %% Always save curve image
    hSaveFig = figure( ...
        'Visible', 'off', ...
        'Name', 'Force vs Depth saved image', ...
        'NumberTitle', 'off');

    plot(depth, force, 'LineWidth', 1.2);
    xlabel('Depth (nm)');
    ylabel('Force (mN)');
    title(sprintf('File: %s', fileName), 'Interpreter', 'none');
    grid on;

    exportgraphics(hSaveFig, outputPngFile, 'Resolution', 300);
    close(hSaveFig);

    fprintf('Saved PNG: %s\n', outputPngFile);
    nImagesSaved = nImagesSaved + 1;

    %% Optional preview
    if showPreview && isvalid(hFig)

        figure(hFig);
        clf(hFig);

        plot(depth, force, 'LineWidth', 1.2);
        xlabel('Depth (nm)');
        ylabel('Force (mN)');
        title(sprintf('File: %s', fileName), 'Interpreter', 'none');
        grid on;

        drawnow;
        pause(3);
    end
end

%% Final report
fprintf('\nDone.\n');
fprintf('Files found:   %d\n', nFiles);
fprintf('MAT saved:     %d\n', nSaved);
fprintf('PNG saved:     %d\n', nImagesSaved);
fprintf('Files skipped: %d\n', nSkipped);