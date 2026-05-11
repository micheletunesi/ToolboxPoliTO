%% =========================
%  General Info
%  =========================
%  Filename: S1_Data_conversion_PoliTO.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 11-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script converts raw point cloud data exported from Sensofar software
%  (PoliTO optical measurements) into structured grid format. The output is a
%  MATLAB structure containing gridded x, y, z data suitable for subsequent
%  surface analysis steps.
%
%  Inputs:
%  - raw .txt files (numeric, n×3): columns represent x, y, z coordinates
%    exported from Sensofar software (PoliTO format)
%
%  Outputs:
%  - data (struct): containing fields:
%    data.active.x, data.active.y, data.active.z (double, m×n grids)
%  - .mat files: structured data saved to disk
%  - .png files: 2D surface plots of the gridded data

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script in a directory containing the folder 'S0_data_raw':
%
%  >> S1_Data_Preparation

%% =========================
%  Parameters
%  =========================
%  - n: downsampling factor used for visualization plots
%  - folder_source: directory containing raw .txt files
%  - folder_output: directory for processed .mat files
%  - folder_output2: directory for generated figures

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    MATLAB base environment (graphics, file I/O)
%  - External functions/files:
%    None

%% =========================
%  Notes
%  =========================
%  - This script is specifically designed for PoliTO data exported from
%    Sensofar optical measurement software.
%  - The raw data is assumed to be ordered such that points can be reshaped
%    into a regular grid without interpolation.
%  - Grid construction is performed by sequential mapping of points based on
%    unique x and y coordinates.
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
folder_source = fullfile(folder_main, 'S0_data_raw');
folder_output = fullfile(folder_main, 'S1_data_prepared');
folder_output2 = fullfile(folder_output, 'figures_rawdata');

output_folders = {folder_output, folder_output2};

for k = 1:numel(output_folders)
    if ~exist(output_folders{k}, 'dir')
        mkdir(output_folders{k});
    end
end

files = dir(fullfile(folder_source, '*.txt'));

downsample_factor = 5;

for i = 1:length(files)

    disp(['Processing file ', num2str(i), '/', num2str(length(files))])

    input_filename = fullfile(folder_source, files(i).name);
    [~, baseName, ~] = fileparts(files(i).name);

    rawdata = readmatrix(input_filename);

    disp(['Filename ', files(i).name, ' loaded'])

    x_raw = rawdata(:,1);
    y_raw = rawdata(:,2);
    z_raw = rawdata(:,3);

    x_unique = unique(x_raw, 'stable');
    y_unique = unique(y_raw, 'stable');

    n_x = numel(x_unique);
    n_y = numel(y_unique);

    if numel(z_raw) ~= n_x * n_y
        error('File %s cannot be reshaped into a regular grid.', files(i).name)
    end

    data = struct();

    data.active.x = reshape(x_raw, n_x, n_y).';
    data.active.y = reshape(y_raw, n_x, n_y).';
    data.active.z = reshape(z_raw, n_x, n_y).';

    data.info.filename = baseName;

    save(fullfile(folder_output, [baseName, '.mat']), 'data', '-v7.3')

    disp(['Filename ', files(i).name, ' data saved'])

    ix = 1:downsample_factor:size(data.active.x, 2);
    iy = 1:downsample_factor:size(data.active.x, 1);

    fig = figure('Visible', 'off');

    surf(data.active.x(iy, ix), ...
         data.active.y(iy, ix), ...
         data.active.z(iy, ix), ...
         LineStyle="none")

    view(0,90)
    xlim([min(data.active.x(:)), max(data.active.x(:))])
    ylim([min(data.active.y(:)), max(data.active.y(:))])

    box on
    colorbar
    axis equal
    title(data.info.filename, Interpreter="none")
    xlabel('Distance [um]')
    ylabel('Distance [um]')

    print(fig, fullfile(folder_output2, [baseName, '.png']), '-dpng')

    close(fig)

    disp(['Filename ', files(i).name, ' figure generated. Moving to next'])

end