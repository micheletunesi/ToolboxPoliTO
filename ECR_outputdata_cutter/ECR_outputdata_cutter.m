%% Interactive MAT-file segment extraction with linear background subtraction
% This script loads a MAT-file containing the variable `AllData`, where:
%   - column 1 is time
%   - column 2 is current
%
% The workflow is interactive:
%   1. The user selects a MAT-file.
%   2. The full signal is plotted together with a moving-mean trace.
%   3. Two points are clicked to define a zoom region.
%   4. One final point is clicked to define the end of the segment of interest.
%   5. A time window of fixed duration is extracted before that point.
%   6. A linear background is estimated from left and right tail regions.
%   7. The extracted segment is background-subtracted and time-shifted to start at zero.
%   8. The processed data are previewed and then saved to a new MAT-file.
%
% Output files are stored in a subfolder named `output_files` created in the
% same directory as the selected input file.
%
% Keyboard controls during point selection:
%   - ESC   : exit the script
%   - ENTER : restart from scratch and select a new input file
%
% Saved variables:
%   - time_select     : extracted time vector, shifted so that it starts at 0
%   - current_select  : extracted current vector after background subtraction
%   - time_full       : full original time vector
%   - current_full    : full original current vector
%   - timestamps      : [t0 tf] of the extracted segment in the original signal

clear
close all
clc

% ---------------- USER PARAMETERS ----------------
tailDuration = 2;   % Duration of each tail region used for background fit, in seconds
mainDuration = 70;  % Duration of the main extracted interval, in seconds
base_filename = 'Al46000_secondario_rep_'; % Base name for saved output files
previewTime = 2;    % Time in seconds for BG subtraction preview display
kk = 1;             % Initial proposed file number for saving
% -------------------------------------------------

% Outer loop:
% Repeats the whole process, allowing the user to select a new MAT-file
% after a restart command.
while true

    % Ask the user to select a MAT-file.
    [filename, pathname] = uigetfile('*.mat', 'Select a MAT-file');

    % Exit if file selection is canceled.
    if isequal(filename, 0)
        disp('File selection canceled.');
        return;
    end

    % Store the input file name for plot titles.
    fileLabel = filename;

    % Inner loop:
    % Repeats processing on the same file until the user decides to restart
    % from scratch or exit.
    while true

        % Build full file path and load the MAT-file.
        fullpath = fullfile(pathname, filename);
        data = load(fullpath);

        % Copy all variables from the MAT-file to the base workspace.
        % This is useful for inspection during interactive use.
        vars = fieldnames(data);
        for i = 1:numel(vars)
            assignin('base', vars{i}, data.(vars{i}));
        end

        disp(['Loaded file: ', fullpath]);

        % Create output directory if it does not already exist.
        outputDir = fullfile(pathname, 'output_files');
        if ~exist(outputDir, 'dir')
            mkdir(outputDir);
        end

        % Check that the required variable exists.
        if ~isfield(data, 'AllData')
            error('The selected MAT-file does not contain the variable AllData.');
        end

        % Extract time and current from AllData.
        time = data.AllData(:,1);
        current = data.AllData(:,2);

        % Keep copies of the full signal for saving later.
        time_full = time;
        current_full = current;

        % Export main vectors to base workspace for inspection.
        assignin('base', 'time', time);
        assignin('base', 'current', current);
        assignin('base', 'time_full', time_full);
        assignin('base', 'current_full', current_full);

        % Compute moving mean for visualization.
        % The averaging window is about 1 second when the time step is valid.
        % If the time step cannot be estimated, use a fallback based on signal length.
        dt = median(diff(time));
        if ~isfinite(dt) || dt <= 0
            movWindowPts = max(5, round(numel(current) / 200));
        else
            movWindowPts = max(5, round(1.0 / dt));
        end
        current_movmean = movmean(current, movWindowPts);

        % Plot the full signal and its moving mean.
        figMain = figure('Name','Selection','NumberTitle','off');
        plot(time, current, '-', 'LineWidth', 0.8);
        hold on;
        plot(time, current_movmean, '-', 'LineWidth', 1.5);
        xlabel('Time (s)');
        ylabel('Current');
        title({fileLabel, ...
            'Select two points to define the zoom region', ...
            'ESC = exit, ENTER = restart from scratch'}, ...
            'Interpreter', 'none');
        grid on;

        % --- FIRST STAGE: ZOOM REGION SELECTION ---
        % The user clicks two points to define the time region to zoom into.
        [xZoomClick, yZoomClick, buttonZoom] = ginput(2);

        % ESC exits the script completely.
        if any(buttonZoom == 27)
            close all;
            return;
        end

        % ENTER restarts from scratch and resets the proposed file number.
        if any(buttonZoom == 13)
            close all;
            kk = 1;
            break;
        end

        % If fewer than two points were selected, close the figure and retry.
        if numel(xZoomClick) < 2
            close(figMain);
            continue;
        end

        % Snap each clicked point to the nearest actual data point in the plot.
        idxZoom = zeros(2,1);
        for k = 1:2
            dist2 = (time - xZoomClick(k)).^2 + (current - yZoomClick(k)).^2;
            [~, idxZoom(k)] = min(dist2);
        end

        xZoomSel = time(idxZoom);
        yZoomSel = current(idxZoom);

        % Mark the snapped zoom points.
        plot(xZoomSel, yZoomSel, 'mo', 'LineWidth', 1.5);

        % Compute zoom limits from the selected points.
        xMin = min(xZoomSel);
        xMax = max(xZoomSel);

        idxWindow = (time >= xMin) & (time <= xMax);
        yMin = min(current(idxWindow));
        yMax = max(current(idxWindow));
        yMargin = 0.05 * (yMax - yMin + eps);

        % Apply the zoom to help the user pick the final point.
        xlim([xMin xMax]);
        ylim([yMin - yMargin, yMax + yMargin]);

        title({fileLabel, 'Zoomed view: select final point'});
        drawnow;

        % --- SECOND STAGE: FINAL POINT SELECTION ---
        % The user clicks one point that defines the end of the main interval.
        [xClick, yClick, buttonFinal] = ginput(1);

        % ESC exits the script completely.
        if any(buttonFinal == 27)
            close all;
            return;
        end

        % ENTER restarts from scratch and resets the proposed file number.
        if any(buttonFinal == 13)
            close all;
            kk = 1;
            break;
        end

        % If no point was selected, close and retry.
        if isempty(xClick)
            close(figMain);
            continue;
        end

        % Snap the final click to the nearest data point.
        dist2 = (time - xClick).^2 + (current - yClick).^2;
        [~, idxClosest] = min(dist2);

        xSelected = time(idxClosest);

        % Mark the selected final point.
        plot(xSelected, current(idxClosest), 'ro', 'LineWidth', 1.5);
        hold off;

        % Define the main interval as the fixed-duration window ending at xSelected.
        tStartMain = xSelected - mainDuration;
        tEndMain = xSelected;

        idxMain = (time >= tStartMain) & (time <= tEndMain);
        time_select_original = time(idxMain);
        current_select_original = current(idxMain);

        % Define left and right tail regions around the main interval.
        % These tails are used to estimate a linear background.
        idxLeftTail  = (time >= tStartMain - tailDuration) & (time < tStartMain);
        idxRightTail = (time > tEndMain) & (time <= tEndMain + tailDuration);

        % Stop if either tail is missing.
        if ~any(idxLeftTail) || ~any(idxRightTail)
            close(figMain);
            error('Tail regions not available. Adjust tailDuration.');
        end

        % Build the background-fit dataset using both tails.
        time_tails = [time(idxLeftTail); time(idxRightTail)];
        current_tails = [current(idxLeftTail); current(idxRightTail)];

        % Fit a first-order polynomial to model the background.
        p_bg = polyfit(time_tails, current_tails, 1);
        bg_main = polyval(p_bg, time_select_original);

        % Subtract the fitted background from the main interval.
        current_select_bgsub = current_select_original - bg_main;

        % Store original start and end times of the selected interval.
        t0 = time_select_original(1);
        tf = time_select_original(end);
        timestamps = [t0, tf];

        % Shift time so that the extracted interval starts at zero.
        time_select = time_select_original - t0;
        current_select = current_select_bgsub;

        % Preview the original and background-subtracted extracted signal.
        figPreview = figure('Name', 'Background subtraction preview', 'NumberTitle', 'off');
        plot(time_select, current_select_original, 'k-', 'LineWidth', 1.2);
        hold on;
        plot(time_select, current_select_bgsub, 'r-', 'LineWidth', 1.2);
        yline(0, 'k--');
        xlabel('Time (s)');
        ylabel('Current');
        title({'Background subtraction preview', fileLabel});
        grid on;

        % Keep the preview visible for a fixed amount of time, then close it.
        pause(previewTime);
        close(figPreview);

        % Ask the user for the file number to use in the output file name.
        answer = inputdlg('File number:', 'Save number', [1 50], {num2str(kk)});

        % If the dialog is canceled, close the main figure and restart the loop.
        if isempty(answer)
            close(figMain);
            continue;
        end

        saveNumber = str2double(strtrim(answer{1}));

        % Validate that the entered number is an integer.
        if ~isfinite(saveNumber) || saveNumber ~= round(saveNumber)
            errordlg('Invalid number');
            close(figMain);
            continue;
        end

        % Build the output file name and full output path.
        saveFile = [base_filename, num2str(saveNumber), '.mat'];
        saveFullPath = fullfile(outputDir, saveFile);

        % Save processed data and original full signal.
        save(saveFullPath, 'time_select', 'current_select', ...
            'time_full', 'current_full', 'timestamps');

        disp(['Saved: ', saveFullPath]);

        % Close the selection figure after saving.
        close(figMain);

        % Update the proposed file number for the next save.
        kk = saveNumber + 1;

        % Continue working on the same input file unless restarted.

    end
end