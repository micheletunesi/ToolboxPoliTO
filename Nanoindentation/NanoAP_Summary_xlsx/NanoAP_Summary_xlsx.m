%% =========================
%  General Info
%  =========================
%  Filename: NanoAP_Summary_xlsx.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 07-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  Converts Anton Paar summary report .txt files into Excel and MATLAB
%  formats. The code detects experiment columns and parameter blocks,
%  stores each parameter as a separate MATLAB table, exports each parameter
%  to a dedicated Excel sheet, and creates a summary sheet.
%
%  Inputs:
%  - inputFile (string, scalar): Anton Paar summary report .txt file selected via GUI
%  - sampleNames (cell array, 1 x n): experiment names detected from the report header
%
%  Outputs:
%  - xlsxFile (Excel file): workbook saved in the input folder with one sheet per parameter
%  - matFile (MAT-file): file saved in the input folder containing parameterTables,
%    parameterNames, parameterUnits, summaryTable, sampleNames, and inputFile

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script and select the Anton Paar summary report .txt file when prompted.
%  The .xlsx and .mat outputs are saved in the same folder with the same base name.

%% =========================
%  Parameters
%  =========================
%  - writeExcel: logical flag to enable or disable Excel export
%  - writeMat: logical flag to enable or disable MAT-file export
%  - parameterTables: cell array containing one table for each detected parameter
%  - parameterNames: cell array containing the detected parameter names
%  - parameterUnits: cell array containing the detected units
%  - summaryTable: table reporting parameter name, unit, row count, and column count

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes: none
%  - External functions/files: Anton Paar summary report in .txt format

%% =========================
%  Notes
%  =========================
%  - The number of experiment columns is detected automatically.
%  - The number of parameter blocks is detected automatically.
%  - Empty numeric cells are stored as NaN.
%  - Optional statistics rows such as Mean, Std Dev, Min, Max, N, and Median
%    are preserved as table rows.
%  - Output files use the same base filename as the input .txt file.

%% =========================
%  Revision History
%  =========================
%  v1.0 (07-05-2026): initial version

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

%% USER SETTINGS
writeExcel = true;
writeMat = true;

%% Select input file
[inputName, inputFolder] = uigetfile( ...
    {'*.txt;*.TXT', 'Text files (*.txt, *.TXT)'}, ...
    'Select Anton Paar report table');

if isequal(inputName, 0)
    error('No file selected.');
end

inputFile = fullfile(inputFolder, inputName);

%% Output files in same folder with same base name
[~, baseName, ~] = fileparts(inputName);

xlsxFile = fullfile(inputFolder, [baseName, '.xlsx']);
matFile  = fullfile(inputFolder, [baseName, '.mat']);

%% Read input file
rawText = fileread(inputFile);
lines = regexp(rawText, '\r\n|\n|\r', 'split');

if ~isempty(lines) && isempty(strtrim(lines{end}))
    lines(end) = [];
end

%% Find experiment header row
headerIdx = NaN;
sampleNames = {};

for i = 1:numel(lines)

    fields = splitLineTabs(lines{i});

    if numel(fields) < 3
        continue;
    end

    candidateNames = fields(3:end);
    candidateNames = candidateNames(~cellfun(@isempty, strtrimCell(candidateNames)));

    if numel(candidateNames) >= 1
        headerIdx = i;
        sampleNames = fields(3:end);
        break;
    end
end

if isnan(headerIdx)
    error('Experiment header row was not found.');
end

nSamples = numel(sampleNames);

validSampleNames = matlab.lang.makeValidName(sampleNames, ...
    'ReplacementStyle', 'delete');
validSampleNames = matlab.lang.makeUniqueStrings(validSampleNames);

%% Initialize containers
parameterNames = {};
parameterUnits = {};
parameterTables = {};

currentName = '';
currentUnit = '';
currentRowLabels = {};
currentValues = [];

%% Parse report table
for i = headerIdx + 1:numel(lines)

    fields = splitLineTabs(lines{i});
    fields = padFields(fields, nSamples + 2);

    firstField = strtrim(fields{1});
    rowLabel = strtrim(fields{2});

    if all(cellfun(@isempty, strtrimCell(fields)))
        continue;
    end

    %% Detect unit row, e.g. [MPa], [GPa], [nm], [pJ]
    if startsWith(firstField, '[') && endsWith(firstField, ']')
        currentUnit = firstField;
        firstField = '';
    end

    %% Detect new parameter block
    if ~isempty(firstField)

        if ~isempty(currentName)
            T = buildParameterTable( ...
                currentRowLabels, ...
                currentValues, ...
                validSampleNames, ...
                currentUnit);

            parameterNames{end + 1, 1} = currentName;
            parameterUnits{end + 1, 1} = currentUnit;
            parameterTables{end + 1, 1} = T;
        end

        currentName = firstField;
        currentUnit = '';
        currentRowLabels = {};
        currentValues = [];
    end

    %% Skip rows without labels
    if isempty(rowLabel)
        continue;
    end

    %% Parse numeric values
    numericValues = NaN(1, nSamples);

    for j = 1:nSamples
        numericValues(j) = parseNumber(fields{j + 2});
    end

    currentRowLabels{end + 1, 1} = rowLabel;
    currentValues(end + 1, :) = numericValues;
end

%% Store final parameter block
if ~isempty(currentName)
    T = buildParameterTable( ...
        currentRowLabels, ...
        currentValues, ...
        validSampleNames, ...
        currentUnit);

    parameterNames{end + 1, 1} = currentName;
    parameterUnits{end + 1, 1} = currentUnit;
    parameterTables{end + 1, 1} = T;
end

if isempty(parameterTables)
    error('No parameter tables were parsed.');
end

%% Build summary table
nParameters = numel(parameterTables);
nRows = zeros(nParameters, 1);
nColumns = zeros(nParameters, 1);

for i = 1:nParameters
    nRows(i) = height(parameterTables{i});
    nColumns(i) = width(parameterTables{i}) - 2;
end

summaryTable = table(parameterNames, parameterUnits, nRows, nColumns, ...
    'VariableNames', {'Parameter', 'Unit', 'Rows', 'ExperimentColumns'});

%% Write Excel file
if writeExcel

    if exist(xlsxFile, 'file')
        delete(xlsxFile);
    end

    writetable(summaryTable, xlsxFile, 'Sheet', 'Summary');

    usedSheetNames = {};

    for i = 1:nParameters

        sheetName = makeExcelSheetName(parameterNames{i}, usedSheetNames);
        usedSheetNames{end + 1} = sheetName;

        writetable(parameterTables{i}, xlsxFile, 'Sheet', sheetName);
    end
end

%% Save MATLAB file
if writeMat
    save(matFile, ...
        'parameterTables', ...
        'parameterNames', ...
        'parameterUnits', ...
        'summaryTable', ...
        'sampleNames', ...
        'inputFile');
end

%% Final report
fprintf('\nDone.\n');
fprintf('Input file: %s\n', inputFile);

if writeExcel
    fprintf('Excel file: %s\n', xlsxFile);
end

if writeMat
    fprintf('MAT file:   %s\n', matFile);
end

fprintf('Parsed parameters: %d\n', nParameters);

%% Local functions
function fields = splitLineTabs(lineText)

    fields = regexp(lineText, '\t', 'split');

end

function out = strtrimCell(in)

    out = cell(size(in));

    for k = 1:numel(in)
        out{k} = strtrim(in{k});
    end

end

function fields = padFields(fields, targetLength)

    if numel(fields) < targetLength
        fields(end + 1:targetLength) = {''};
    elseif numel(fields) > targetLength
        fields = fields(1:targetLength);
    end

end

function value = parseNumber(textValue)

    textValue = strtrim(textValue);
    textValue = strrep(textValue, ',', '.');

    if isempty(textValue)
        value = NaN;
        return;
    end

    value = str2double(textValue);

    if isnan(value)
        value = NaN;
    end

end

function T = buildParameterTable(rowLabels, values, sampleNames, unitText)

    T = array2table(values, 'VariableNames', sampleNames);

    T = addvars(T, rowLabels, ...
        'Before', 1, ...
        'NewVariableNames', 'RowLabel');

    unitColumn = repmat({unitText}, height(T), 1);

    T = addvars(T, unitColumn, ...
        'After', 'RowLabel', ...
        'NewVariableNames', 'Unit');

end

function sheetName = makeExcelSheetName(rawName, usedNames)

    sheetName = regexprep(rawName, '[\\/*?:\[\]]', '_');
    sheetName = strtrim(sheetName);

    if isempty(sheetName)
        sheetName = 'Sheet';
    end

    maxLength = 31;
    sheetName = sheetName(1:min(numel(sheetName), maxLength));

    baseSheetName = sheetName;
    counter = 1;

    while any(strcmpi(sheetName, usedNames))
        suffix = sprintf('_%d', counter);
        keepLength = maxLength - numel(suffix);
        sheetName = [baseSheetName(1:min(numel(baseSheetName), keepLength)), suffix];
        counter = counter + 1;
    end

end