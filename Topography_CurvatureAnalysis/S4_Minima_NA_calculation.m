%% =========================
%  General Info
%  =========================
%  Filename: S4_Minima_NA_calculation.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 11-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script processes linearized surface data to compute characteristic
%  geometric features. It identifies the minimum curvature points within
%  predefined spatial ranges and determines NA crossing points based on a
%  slope-angle threshold. Results are stored and exported together with
%  global diagnostic plots.
%
%  Inputs:
%  - data.curvature (double, m×n): curvature values of the surface
%  - data.slope_angle (double, m×n): slope angle values in degrees
%  - data.axes.x (double, m×n): x-coordinates of the grid
%  - data.axes.y (double, m×n): y-coordinates of the grid
%  - data.minima_selection (struct): contains sx and dx limits for search ranges
%
%  Outputs:
%  - data (struct): updated structure including:
%    minima_calc (sx, dx) and NA (sx, dx) fields
%  - .mat files: processed data saved to disk
%  - .png files: global plots for minima and NA distributions

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script in a directory containing the folder 'S3_linearize':
%
%  >> S4_Minima_NA_calculation

%% =========================
%  Parameters
%  =========================
%  - NA_value: threshold value used to compute NA crossing
%  - NA_angle: corresponding angle in degrees (asind(NA_value))
%  - fields_to_remove: list of unused fields removed before saving

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    MATLAB base environment (graphics, file I/O)
%  - External functions/files:
%    findCrossing (required for NA calculation)

%% =========================
%  Notes
%  =========================
%  - The script assumes structured grid data.
%  - Minima are computed as the minimum curvature within predefined ranges.
%  - NA points are computed as slope-angle crossings using a threshold.
%  - The function findCrossing must be available in the MATLAB path.
%  - Output folders are created automatically if not present.
%  - Global plots represent spatial distributions along x-direction.

%% =========================
%  Revision History
%  =========================
%  v1.0 (11-05-2026): initial version

%% =========================
%  License
%  =========================
%  This work is licensed under the Creative Commons
%  Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
%  You are free to reuse and adapt this code for non-commercial purposes,
%  provided that appropriate credit is given to the original author.
%  License details: https://creativecommons.org/licenses/by-nc/4.0/

clear
clc
close all

%% Folder setup

folder_main = pwd;
folder_source = fullfile(folder_main, 'S3_linearize');
folder_output = fullfile(folder_main, 'S4_Minima_NA_calculation');

folder_output_minima_global = fullfile(folder_output, 'minima', 'global_plots');
folder_output_NA_global = fullfile(folder_output, 'NA', 'global_plots');

output_folders = {
    folder_output
    folder_output_minima_global
    folder_output_NA_global
};

for k = 1:numel(output_folders)
    if ~exist(output_folders{k}, 'dir')
        mkdir(output_folders{k});
    end
end

files = dir(fullfile(folder_source, '*.mat'));

%% Parameters

NA_value = 0.45;
NA_angle = asind(NA_value);
NA_label = sprintf('NA %.2f (%.1f deg)', NA_value, NA_angle);

fields_to_remove = {
    'raw'
    'rawgrid'
    'cut_original'
    'prelinearization'
};

%% Process files

for i = 1:length(files)

    disp(['Processing file ', num2str(i), '/', num2str(length(files))])

    input_filename = fullfile(folder_source, files(i).name);
    [~, baseName, ~] = fileparts(files(i).name);

    load(input_filename)

    disp(['Filename ', files(i).name, ' loaded'])

    %% Minimum curvature calculation

    n_profiles = size(data.curvature, 2);

    data.minima_calc.sx = nan(n_profiles, 2);
    data.minima_calc.dx = nan(n_profiles, 2);

    sx_range = sort(data.minima_selection.sx);
    dx_range = sort(data.minima_selection.dx);

    for col = 1:n_profiles

        y_line = data.axes.y(:, col);
        curvature_line = data.curvature(:, col);

        % SX side
        sx_idx = y_line > sx_range(1) & y_line < sx_range(2);
        y_sx = y_line(sx_idx);
        curvature_sx = curvature_line(sx_idx);

        if ~isempty(y_sx)
            [min_sx, idx_sx] = min(curvature_sx);
            data.minima_calc.sx(col, :) = [y_sx(idx_sx), min_sx];
        end

        % DX side
        dx_idx = y_line > dx_range(1) & y_line < dx_range(2);
        y_dx = y_line(dx_idx);
        curvature_dx = curvature_line(dx_idx);

        if ~isempty(y_dx)
            [min_dx, idx_dx] = min(curvature_dx);
            data.minima_calc.dx(col, :) = [y_dx(idx_dx), min_dx];
        end

    end

    disp('Minima calculation concluded')

    %% Save global minima plot

    figure(i)

    scatter(data.axes.x(1,:)', data.minima_calc.sx(:,1), 'k', 'filled')
    hold on
    scatter(data.axes.x(1,:)', data.minima_calc.dx(:,1), 'k', 'filled')
    hold off

    axis equal
    box on
    set(gcf, "Position", [100 100 700 400])

    xlabel('X [um]')
    ylabel('Y [um]')
    title(['Minima calculation for ', files(i).name], Interpreter="none")

    output_minima_plot = fullfile(folder_output_minima_global, [baseName, '.png']);
    saveas(gcf, output_minima_plot)

    close(i)

    %% Remove unused fields if present

    for k = 1:numel(fields_to_remove)
        if isfield(data, fields_to_remove{k})
            data = rmfield(data, fields_to_remove{k});
        end
    end

    %% NA calculation

    n_profiles = size(data.slope_angle, 2);

    data.NA.sx = nan(n_profiles, 2);
    data.NA.dx = nan(n_profiles, 2);
    data.info.NA = [NA_value, NA_angle];

    for col = 1:n_profiles

        y_line = data.axes.y(:, col);
        slope_angle_line = data.slope_angle(:, col);
        y_mid = y_line(round(numel(y_line) / 2));

        % SX side:
        % Searches between profile midpoint and SX minima boundary.
        sx_idx = y_line > y_mid & y_line < data.minima_selection.sx(1);
        y_sx = y_line(sx_idx);
        slope_sx = slope_angle_line(sx_idx);

        if ~isempty(y_sx)
            % findCrossing is an external function.
            [NA_xCross_sx, NA_yCross_sx, ~] = ...
                findCrossing(y_sx, slope_sx, NA_angle, 'backward', 'positive');

            data.NA.sx(col, :) = [NA_xCross_sx, NA_yCross_sx];
        end

        % DX side:
        % Searches between DX minima boundary and profile midpoint.
        dx_idx = y_line > data.minima_selection.dx(2) & y_line < y_mid;
        y_dx = y_line(dx_idx);
        slope_dx = slope_angle_line(dx_idx);

        if ~isempty(y_dx)
            % findCrossing is an external function.
            [NA_xCross_dx, NA_yCross_dx, ~] = ...
                findCrossing(y_dx, slope_dx, -NA_angle, 'forward', 'negative');

            data.NA.dx(col, :) = [NA_xCross_dx, NA_yCross_dx];
        end

    end

    disp('NA calculation concluded')

    %% Save global NA plot

    figure(i)

    scatter(data.axes.x(1,:)', data.NA.sx(:,1), 'k', 'filled')
    hold on
    scatter(data.axes.x(1,:)', data.NA.dx(:,1), 'k', 'filled')
    hold off

    axis equal
    box on
    set(gcf, "Position", [100 100 700 400])

    xlabel('X [um]')
    ylabel('Y [um]')
    title([NA_label, ' calculation for ', files(i).name], Interpreter="none")

    output_NA_plot = fullfile(folder_output_NA_global, [baseName, '.png']);
    saveas(gcf, output_NA_plot)

    close(i)

    %% Save processed data

    output_filename = fullfile(folder_output, [baseName, '.mat']);
    save(output_filename, 'data', '-v7.3')

    disp('Data saved. MOVING TO NEXT...')

end