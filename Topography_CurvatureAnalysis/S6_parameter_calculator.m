%% =========================
%  General Info
%  =========================
%  Filename: S6_parameter_calculator.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 18-05-2026
%  Version: 2.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This script processes multiple .mat files containing minima coordinate
%  data, automatically estimates the maximum distance between two point
%  sets, and allows optional manual correction through graphical point
%  selection. The selected distance is stored inside the updated data
%  structure and exported to Excel together with the measurement method.
%
%  Inputs:
%  - .mat files (struct): files containing the variable "data"
%  - data.minima_calc.sx (Nx1 double): left minima coordinates
%  - data.minima_calc.dx (Nx1 double): right minima coordinates
%
%  Outputs:
%  - Updated .mat files containing:
%       - data.size_pts (2x2 double): selected points
%       - data.size (1x1 double): measured distance
%       - data.size_method (char): "auto" or "manual"
%  - .png figures showing the accepted measurement
%  - .fig MATLAB figure files
%  - Distances_manual.xlsx containing:
%       - filename
%       - measured distance
%       - measurement method

%% =========================
%  Usage
%  =========================
%  Example:
%  Run the script directly from MATLAB:
%
%  >> parameter_calculator_manual_distance
%
%  Required folder structure:
%  ./S4_Minima_NA_calculation/
%  ./S6_parameter_calculator/

%% =========================
%  Parameters
%  =========================
%  - folder_source: input folder containing .mat files
%  - folder_output: output folder for processed results
%  - dist_auto: automatically calculated maximum distance
%  - dist_manual: manually selected distance
%  - method_val: accepted measurement mode ("auto" or "manual")

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%       - MATLAB base functions
%
%  - External functions/files:
%       - None

%% =========================
%  Notes
%  =========================
%  - The automatic distance calculation searches for the most distant pair
%    between the sx and dx point sets.
%  - Manual point selection uses nearest-neighbor snapping to the plotted
%    coordinates.
%  - Keyboard controls:
%       - Enter: accept automatic distance
%       - Spacebar: switch to manual mode
%       - ESC: stop execution
%  - Mouse clicks are ignored during the automatic acceptance stage.
%  - Existing Excel output files are overwritten at each execution.

%% =========================
%  Revision History
%  =========================
%  v1.0 (13-02-2026): initial version
%  v2.0 (18-05-2026): added automatic distance calculation and refined
%  manual distance calculation procedure


%% =========================
%  License
%  =========================
%  This work is licensed under the Creative Commons
%  Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0).
%  You are free to reuse and adapt this code for non-commercial purposes,
%  provided that appropriate credit is given to the original author.
%  License details: https://creativecommons.org/licenses/by-nc/4.0/

clear; clc;

%% Folder setup

folder_main   = pwd;
folder_source = fullfile(folder_main, 'S4_Minima_NA_calculation');
folder_output = fullfile(folder_main, 'S6_parameter_calculator');

files = dir(fullfile(folder_source, '*.mat'));
nFiles = numel(files);

disp('----------------------------------------');
disp(['Found ' num2str(nFiles) ' .mat files in source folder.']);

% Create output folder if needed
if ~isfolder(folder_output)
    mkdir(folder_output);
    disp(['Created output folder: ' folder_output]);
else
    disp(['Output folder found: ' folder_output]);
end

%% Excel setup

xlsx_path = fullfile(folder_output, 'Distances_manual.xlsx');

% Start from a clean Excel output file
if isfile(xlsx_path)
    delete(xlsx_path);
    disp('Existing Excel file deleted.');
end

% Create Excel header
writecell({'filename','distance','method'}, xlsx_path, 'Sheet', 1, 'Range', 'A1');
disp(['Created Excel file: ' xlsx_path]);

xlsx_row = 2;

%% Main processing loop

for k = 1:nFiles

    disp('----------------------------------------');
    disp(['Processing file ' num2str(k) ' of ' num2str(nFiles) ': ' files(k).name]);
    disp('Loading data...');

    mat_path = fullfile(files(k).folder, files(k).name);
    S = load(mat_path);

    % Check expected variable
    if ~isfield(S, 'data')
        warning(['Skipping ' files(k).name ' (variable "data" not found).']);
        continue;
    end

    data = S.data;

    % Extract minima coordinates
    y_sx = data.minima_calc.sx(:,1);
    y_dx = data.minima_calc.dx(:,1);

    n = length(y_sx);

    % Check consistency between sx and dx arrays
    if length(y_dx) ~= n
        warning(['Skipping ' files(k).name ' (sx and dx lengths differ).']);
        continue;
    end

    % Use sample index as x-coordinate
    x = (0:(n-1)).';

    pts_sx = [x y_sx];
    pts_dx = [x y_dx];

    % Combined point list for nearest-point snapping during manual mode
    Xall = [pts_sx(:,1); pts_dx(:,1)];
    Yall = [pts_sx(:,2); pts_dx(:,2)];

    %% Automatic distance calculation

    disp('Calculating automatic maximum distance between sx and dx...');

    [snapped_auto, dist_auto] = find_max_distance_between_sets(pts_sx, pts_dx);

    disp(['Automatic distance found: ' num2str(dist_auto, '%.6g')]);
    disp('Opening automatic measurement plot...');
    disp('Press Enter to accept automatic measurement, Space for manual selection, or ESC to stop.');

    %% Show automatic result

    fig = figure('Name', files(k).name, 'Color', 'w');
    ax = axes(fig);

    plot_current_result(ax, x, y_sx, y_dx, snapped_auto, dist_auto, ...
        files(k).name, 'Automatic distance');

    title(ax, {files(k).name; ...
        ['Automatic distance = ' num2str(dist_auto, '%.6g')]; ...
        'Press Enter to save, Space to select points manually, or ESC to stop'}, ...
        'Interpreter', 'none');

    drawnow;

    %% User decision on automatic result

    decision = wait_for_enter_space_or_esc(fig);

    if strcmp(decision, 'save_auto')

        disp('Automatic measurement accepted.');

        snapped = snapped_auto;
        dist_val = dist_auto;
        method_val = 'auto';

    else

        disp('Manual measurement mode selected.');

        manual_done = false;

        while ~manual_done

            %% Manual point selection

            plot_base_points(ax, x, y_sx, y_dx, files(k).name, ...
                'Manual mode: click two points');

            snapped_manual = zeros(2,2);

            disp('Click the first point.');
            snapped_manual(1,:) = get_snapped_point(ax, Xall, Yall);
            disp(['First point selected: x = ' num2str(snapped_manual(1,1)) ...
                ', y = ' num2str(snapped_manual(1,2))]);

            disp('Click the second point.');
            snapped_manual(2,:) = get_snapped_point(ax, Xall, Yall);
            disp(['Second point selected: x = ' num2str(snapped_manual(2,1)) ...
                ', y = ' num2str(snapped_manual(2,2))]);

            % Compute manual distance
            dist_manual = hypot(snapped_manual(2,1) - snapped_manual(1,1), ...
                                snapped_manual(2,2) - snapped_manual(1,2));

            % Show manual result
            plot(ax, snapped_manual(:,1), snapped_manual(:,2), ...
                'r-', 'LineWidth', 1.5);

            title(ax, {files(k).name; ...
                ['Manual distance = ' num2str(dist_manual, '%.6g')]}, ...
                'Interpreter', 'none');

            drawnow;

            disp(['Manual distance selected: ' num2str(dist_manual, '%.6g')]);

            %% Confirm manual result

            answer = questdlg( ...
                ['Manual distance = ' num2str(dist_manual, '%.6g')], ...
                'Save manual measurement?', ...
                'Save', 'Start over', 'Save');

            if strcmp(answer, 'Save')
                disp('Manual measurement accepted.');

                snapped = snapped_manual;
                dist_val = dist_manual;
                method_val = 'manual';
                manual_done = true;
            else
                disp('Manual measurement rejected. Restarting manual selection for this file.');
            end
        end
    end

    %% Store result in data structure

    data.size_pts    = snapped;
    data.size        = dist_val;
    data.size_method = method_val;

    %% Save updated .mat file

    disp('Saving updated .mat file...');

    mat_out_path = fullfile(folder_output, files(k).name);
    save(mat_out_path, 'data');

    %% Save final accepted figure

    plot_current_result(ax, x, y_sx, y_dx, snapped, dist_val, ...
        files(k).name, ['Accepted distance (' method_val ')']);

    [~, base_out, ~] = fileparts(files(k).name);
    png_path = fullfile(folder_output, [base_out '.png']);
    fig_path = fullfile(folder_output, [base_out '.fig']);

    disp('Saving figure files...');
    savefig(fig, fig_path);
    exportgraphics(fig, png_path, 'Resolution', 300);

    %% Write Excel row

    if isfield(data, 'info') && isfield(data.info, 'filename')
        fname_for_log = char(data.info.filename);
    else
        [~, base, ~] = fileparts(files(k).name);
        fname_for_log = base;
    end

    disp('Writing result to Excel...');
    writecell({fname_for_log, dist_val, method_val}, xlsx_path, ...
        'Sheet', 1, 'Range', ['A' num2str(xlsx_row)]);

    xlsx_row = xlsx_row + 1;

    close(fig);

    disp(['Completed file: ' files(k).name]);
end

disp('----------------------------------------');
disp('Processing completed.');

%% Local functions

function [snapped_auto, dist_auto] = find_max_distance_between_sets(pts_sx, pts_dx)
% Finds the most distant pair between the sx and dx point sets.
% The implementation uses a loop to avoid allocating an n-by-n distance matrix.

    n = size(pts_sx, 1);

    max_d2 = -inf;
    idx_sx_best = 1;
    idx_dx_best = 1;

    for i = 1:n

        dx_vec = pts_dx(:,1) - pts_sx(i,1);
        dy_vec = pts_dx(:,2) - pts_sx(i,2);
        d2_vec = dx_vec.^2 + dy_vec.^2;

        [d2_i, idx_i] = max(d2_vec);

        if d2_i > max_d2
            max_d2 = d2_i;
            idx_sx_best = i;
            idx_dx_best = idx_i;
        end
    end

    snapped_auto = [
        pts_sx(idx_sx_best,:);
        pts_dx(idx_dx_best,:)
    ];

    dist_auto = sqrt(max_d2);
end

function decision = wait_for_enter_space_or_esc(fig)
% Waits for keyboard input.
% Enter accepts the automatic measurement.
% Space starts manual mode.
% ESC stops the script.
% Mouse clicks and all other keys are ignored.

    decision = '';

    while isempty(decision)

        was_key = waitforbuttonpress;

        if was_key == 0
            disp('Mouse click ignored. Press Enter, Space, or ESC.');
            continue;
        end

        key = get(fig, 'CurrentCharacter');

        if double(key) == 13

            decision = 'save_auto';

        elseif double(key) == 32

            decision = 'manual';

        elseif double(key) == 27

            disp('ESC pressed. Stopping execution.');
            close(fig);
            error('Execution stopped by user.');

        else

            disp('Key ignored. Press Enter, Space, or ESC.');

        end
    end
end

function snapped_point = get_snapped_point(ax, Xall, Yall)
% Gets one mouse click and snaps it to the nearest plotted point.

    [xc, yc] = ginput(1);

    d2 = (Xall - xc).^2 + (Yall - yc).^2;
    [~, idx] = min(d2);

    xs = Xall(idx);
    ys = Yall(idx);

    snapped_point = [xs ys];

    scatter(ax, xs, ys, 60, 'r', 'filled');
    drawnow;
end

function plot_base_points(ax, x, y_sx, y_dx, file_name, title_txt)
% Plots sx and dx points without selected measurement points.

    cla(ax);
    hold(ax, 'on');

    scatter(ax, x, y_sx, 15, 'k', 'filled');
    scatter(ax, x, y_dx, 15, 'k', 'filled');

    format_axes(ax, y_sx, y_dx);

    title(ax, {file_name; title_txt}, 'Interpreter', 'none');
end

function plot_current_result(ax, x, y_sx, y_dx, snapped, dist_val, file_name, label_txt)
% Plots sx and dx points plus the selected distance segment.

    cla(ax);
    hold(ax, 'on');

    scatter(ax, x, y_sx, 15, 'k', 'filled');
    scatter(ax, x, y_dx, 15, 'k', 'filled');

    scatter(ax, snapped(:,1), snapped(:,2), 60, 'r', 'filled');
    plot(ax, snapped(:,1), snapped(:,2), 'r-', 'LineWidth', 1.5);

    format_axes(ax, y_sx, y_dx);

    title(ax, {file_name; ...
        [label_txt ' = ' num2str(dist_val, '%.6g')]}, ...
        'Interpreter', 'none');
end

function format_axes(ax, y_sx, y_dx)
% Applies common axis formatting.

    axis(ax, 'equal');
    box(ax, 'on');
    grid(ax, 'on');
    xlabel(ax, 'x');
    ylabel(ax, 'y');

    ymin = min([y_sx; y_dx]);
    ymax = max([y_sx; y_dx]);

    yrange = ymax - ymin;
    if yrange == 0
        yrange = 1;
    end

    ylim(ax, [ymin - 0.2*yrange, ymax + 0.2*yrange]);
end