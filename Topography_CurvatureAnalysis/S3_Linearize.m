%% =========================
%  General Info
%  =========================
%  Filename: S3_Linearize.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 11-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script processes cropped surface data with predefined minima ranges.
%  It performs local linear fitting along each profile, calculates slope,
%  converts slope to angle, and computes curvature. Results are stored and
%  exported together with diagnostic plots.
%
%  Inputs:
%  - data.active.x (double, m×n): x-coordinates of the grid
%  - data.active.y (double, m×n): y-coordinates of the grid
%  - data.active.z (double, m×n): surface values
%  - data.minima_selection (struct): contains sx and dx limits for minima regions
%
%  Outputs:
%  - data (struct): updated structure with fields:
%    linear, slope, slope_angle, curvature, axes
%  - .mat files: processed data saved to disk
%  - .png files: diagnostic figures showing linearization and curvature

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script in a directory containing the folder 'S2_data_minima':
%  
%  >> S3_Linearize

%% =========================
%  Parameters
%  =========================
%  - linearization_window: number of points used for local linear fitting
%  - half_window: half-width of the fitting window

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    MATLAB base environment (graphics, file I/O, polyfit)
%  - External functions/files:
%    None

%% =========================
%  Notes
%  =========================
%  - The script assumes structured grid data.
%  - Linearization is performed along the y-direction for each column.
%  - Curvature is computed as the discrete derivative of the slope.
%  - Output folders are created automatically if not present.
%  - Diagnostic plots show full profiles and selected minima regions.

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
folder_source = fullfile(folder_main, 'S2_data_minima');
folder_output = fullfile(folder_main, 'S3_linearize');
folder_output_figures = fullfile(folder_output, 'figures');

if ~exist(folder_output, 'dir')
    mkdir(folder_output);
end

if ~exist(folder_output_figures, 'dir')
    mkdir(folder_output_figures);
end

files = dir(fullfile(folder_source, '*.mat'));

%% Parameters

linearization_window = 10;
half_window = floor(linearization_window / 2);

%% Process files

for i = 1:length(files)

    disp(['Processing file ', num2str(i), '/', num2str(length(files))])

    input_filename = fullfile(folder_source, files(i).name);
    load(input_filename)

    disp(['Filename ', files(i).name, ' loaded'])

    % Avoid .mat.mat and .png.png duplicated extensions
    [~, baseName, ~] = fileparts(data.info.filename);
    data.info.filename = baseName;

    % Store original cropped data before processing
    data.cut_original = data.active;
    data.prelinearization = data.active;

    % Extract active grids
    X = data.active.x;
    Y = data.active.y;
    Z = data.active.z;

    % Preallocate output matrices
    data.linear = nan(size(Z));
    data.slope = nan(size(Z));
    data.curvature = nan(size(Z));
    data.info.linearization_window = linearization_window;

    disp('Line by line processing begins')

    %% Line-by-line local linearization

    for col = 1:size(Z, 2)

        line_y = Y(:, col);
        line_z = Z(:, col);

        % Local linear fit along y for each valid center point
        for row = (1 + half_window):(length(line_y) - half_window)

            fit_idx = row-half_window:row+half_window;

            local_y = line_y(fit_idx);
            local_z = line_z(fit_idx);

            p = polyfit(local_y, local_z, 1);

            data.linear(row, col) = polyval(p, line_y(row));
            data.slope(row, col) = p(1);

        end

        % Curvature is calculated as the derivative of the slope
        for row = (2 + half_window):(length(line_y) - half_window)

            dy = line_y(row) - line_y(row-1);
            data.curvature(row, col) = ...
                (data.slope(row, col) - data.slope(row-1, col)) / dy;

        end

    end

    data.slope_angle = atand(data.slope);

    disp('Line by line processing end')

    %% Store axes and remove active field

    data.axes.x = X;
    data.axes.y = Y;

    data = rmfield(data, 'active');

    %% Diagnostic figure

    midpoint = round(size(data.axes.x, 2) / 2);

    figure(i)

    y_mid = data.axes.y(:, midpoint);
    linear_mid = data.linear(:, midpoint);
    slope_angle_mid = data.slope_angle(:, midpoint);
    curvature_mid = data.curvature(:, midpoint);

    plot_limits_y = [min(y_mid) max(y_mid)];

    % Linearized height profile
    subplot(4,2,[1,2])
    plot(y_mid, linear_mid, 'k')
    hold on
    plotMinimaLimits(data.minima_selection, linear_mid)
    hold off
    xlim(plot_limits_y)
    ylim([min(linear_mid) max(linear_mid)])
    xlabel('Position [um]')
    ylabel('Z height [um]')
    box on

    % Slope angle profile
    subplot(4,2,[3,4])
    plot(y_mid, slope_angle_mid, 'k')
    hold on
    plotMinimaLimits(data.minima_selection, slope_angle_mid)
    hold off
    xlim(plot_limits_y)
    ylim([min(slope_angle_mid) max(slope_angle_mid)])
    xlabel('Position [um]')
    ylabel('Slope [degrees]')
    box on

    % Curvature profile
    subplot(4,2,[5,6])
    plot(y_mid, curvature_mid, 'k')
    hold on
    plotMinimaLimits(data.minima_selection, curvature_mid)
    hold off
    xlim(plot_limits_y)
    ylim([min(curvature_mid) max(curvature_mid)])
    xlabel('Position [um]')
    ylabel('Curvature [1/um]')
    box on

    % SX curvature range
    subplot(4,2,8)
    sx_idx = getRangeIndex(y_mid, data.minima_selection.sx);
    plot(y_mid(sx_idx), curvature_mid(sx_idx), 'k')
    xlim([min(y_mid(sx_idx)) max(y_mid(sx_idx))])
    ylim([min(curvature_mid) max(curvature_mid)])
    xlabel('Position [um]')
    ylabel('Curvature SX [1/um]')
    box on

    % DX curvature range
    subplot(4,2,7)
    dx_idx = getRangeIndex(y_mid, data.minima_selection.dx);
    plot(y_mid(dx_idx), curvature_mid(dx_idx), 'k')
    xlim([min(y_mid(dx_idx)) max(y_mid(dx_idx))])
    ylim([min(curvature_mid) max(curvature_mid)])
    xlabel('Position [um]')
    ylabel('Curvature DX [1/um]')
    box on

    sgtitle(data.info.filename, Interpreter="none")

    %% Save outputs

    output_filename_png = fullfile(folder_output_figures, [data.info.filename, '.png']);
    output_filename_mat = fullfile(folder_output, [data.info.filename, '.mat']);

    print(output_filename_png, '-dpng')
    save(output_filename_mat, 'data', '-v7.3')

    disp(['Filename ', files(i).name, ' figure saved as PNG'])
    disp(['Filename ', files(i).name, ' data saved. MOVING TO NEXT'])

    close(i)

end

%% Local functions

function plotMinimaLimits(minima_selection, y_data)

    y_limits = [min(y_data) max(y_data)];

    for k = 1:2

        plot([minima_selection.sx(k) minima_selection.sx(k)], ...
             y_limits, 'b', LineWidth=2)

        plot([minima_selection.dx(k) minima_selection.dx(k)], ...
             y_limits, 'b', LineWidth=2)

    end

end

function idx = getRangeIndex(position, limits)

    range_limits = sort(limits);
    idx = position > range_limits(1) & position < range_limits(2);

end