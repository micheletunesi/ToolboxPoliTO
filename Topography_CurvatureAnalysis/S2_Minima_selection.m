%% =========================
%  General Info
%  =========================
%  Filename: S2_Minima_selection.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 11-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script processes gridded surface data (x, y, z) stored in .mat files.
%  It allows interactive selection of a rectangular region of interest and
%  identification of two y-ranges corresponding to minima regions via user input.
%  The processed data and corresponding plots are saved to disk.
%
%  Inputs:
%  - data.active.x (double, m×n): x-coordinates of the grid
%  - data.active.y (double, m×n): y-coordinates of the grid
%  - data.active.z (double, m×n): z-values of the surface
%
%  Outputs:
%  - data (struct): updated structure containing cropped data and minima ranges
%  - .mat files: saved processed data
%  - .png files: saved visualization of minima selection

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script in a directory containing the folder 'S1_data_prepared'
%  with valid input .mat files:
%
%  >> area_minima_selection

%% =========================
%  Parameters
%  =========================
%  - downsample_step: subsampling factor for visualization
%  - folder_source: input directory containing .mat files
%  - folder_output: directory for processed data
%  - folder_output2: directory for generated figures

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    MATLAB base functions (graphics and I/O)
%  - External functions/files:
%    None

%% =========================
%  Notes
%  =========================
%  - The script assumes structured grid data.
%  - User interaction via ginput is required for region and minima selection.
%  - Output folders are created automatically if not present.

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

folder_main = pwd;
folder_source = fullfile(folder_main, 'S1_data_prepared');
folder_output = fullfile(folder_main, 'S2_data_minima');
folder_output2 = fullfile(folder_output, 'minima_ranges');

if ~exist(folder_output, 'dir')
    mkdir(folder_output);
end

if ~exist(folder_output2, 'dir')
    mkdir(folder_output2);
end

files = dir(fullfile(folder_source, '*.mat'));

downsample_step = 5;

for i = 1:length(files)

    disp(['Processing file ', num2str(i), '/', num2str(length(files))]);

    input_filename = fullfile(folder_source, files(i).name);
    [~, baseName, ~] = fileparts(files(i).name);

    load(input_filename)

    disp(['Filename ', files(i).name, ' loaded']);

    data.rawgrid = data.active;

    X = data.active.x;
    Y = data.active.y;
    Z = data.active.z;

    z_top = max(Z(:), [], 'omitnan');

    %% Plot original surface and select crop rectangle

    figure(3*i-2)

    row_idx = 1:downsample_step:size(X, 1);
    col_idx = 1:downsample_step:size(X, 2);

    surf(X(row_idx, col_idx), Y(row_idx, col_idx), Z(row_idx, col_idx), LineStyle="none")
    view(0,90)
    box on
    colorbar
    hold on

    x_limits = [min(X(:)), max(X(:))];
    y_limits = [min(Y(:)), max(Y(:))];

    xlim(x_limits)
    ylim(y_limits)

    title([files(i).name, ' Click two corners of the rectangle'], Interpreter="none")
    xlabel('Distance [um]')
    ylabel('Distance [um]')

    plot3(x_limits, mean(y_limits) * [1 1], z_top * [1 1], "r--", "LineWidth", 1.5)
    plot3(mean(x_limits) * [1 1], y_limits, z_top * [1 1], "r--", "LineWidth", 1.5)

    hold off

    [x_click, y_click] = ginput(2);

    x_vec = X(1,:);
    y_vec = Y(:,1);

    [~, col1] = min(abs(x_vec - x_click(1)));
    [~, col2] = min(abs(x_vec - x_click(2)));
    [~, row1] = min(abs(y_vec - y_click(1)));
    [~, row2] = min(abs(y_vec - y_click(2)));

    x_crop = sort([x_vec(col1), x_vec(col2)]);
    y_crop = sort([y_vec(row1), y_vec(row2)]);

    hold on
    plot3([x_crop(1) x_crop(2) x_crop(2) x_crop(1) x_crop(1)], ...
          [y_crop(1) y_crop(1) y_crop(2) y_crop(2) y_crop(1)], ...
          z_top * ones(1, 5), "k-", "LineWidth", 1.5)
    hold off

    rows_keep = any(Y >= y_crop(1) & Y <= y_crop(2), 2);
    cols_keep = any(X >= x_crop(1) & X <= x_crop(2), 1);

    data.active.x = X(rows_keep, cols_keep);
    data.active.y = Y(rows_keep, cols_keep);
    data.active.z = Z(rows_keep, cols_keep);

    data.active.x = data.active.x - min(data.active.x(:));
    data.active.y = data.active.y - min(data.active.y(:));

    pause(1)

    %% Plot cropped surface and select minima ranges

    figure(3*i-1)

    X = data.active.x;
    Y = data.active.y;
    Z = data.active.z;

    z_top = max(Z(:), [], 'omitnan');
    x_limits = [min(X(:)), max(X(:))];

    surf(X, Y, Z, LineStyle="none")
    view(0,90)
    box on
    colorbar
    hold on

    title([files(i).name, ' cut'], Interpreter="none")
    xlabel('Distance [um]')
    ylabel('Distance [um]')

    [~, y_click] = ginput(4);

    y_vec = Y(:,1);
    y_snap = zeros(size(y_click));

    for k = 1:numel(y_click)
        [~, idx] = min(abs(y_vec - y_click(k)));
        y_snap(k) = y_vec(idx);

        plot3(x_limits, y_snap(k) * [1 1], z_top * [1 1], "b--", LineWidth=2)
    end

    data.minima_selection.sx = y_snap(1:2).';
    data.minima_selection.dx = y_snap(3:4).';

    %% Save data and plot

    data.info.filename = baseName;

    output_filename = fullfile(folder_output, [baseName, '.mat']);
    output_figure = fullfile(folder_output2, [baseName, '.png']);

    save(output_filename, 'data', '-v7.3');
    print(output_figure, '-dpng');

    disp(['Filename ', files(i).name, ' data saved']);
    disp(['Filename ', files(i).name, ' figure generated. Moving to next']);

    pause(1)

    close(3*i-2)
    close(3*i-1)

end