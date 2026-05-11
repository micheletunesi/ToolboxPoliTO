%% =========================
%  General Info
%  =========================
%  Filename: findCrossing.m
%  Creator: Michele Tunesi
%  Email: michele.tunesi@polito.it
%  Date: 11-05-2026
%  Version: 1.0

%% =========================
%  Code Description
%  =========================
%  Abstract:
%  This function detects the first crossing of a numeric vector Y through a
%  specified threshold value. The search can be performed in forward or
%  backward direction and can detect either positive or negative crossings.
%  If an exact threshold match is found, that sample is returned. Otherwise,
%  the function returns the last sample before the crossing. If no crossing
%  is detected, NaN values are returned.
%
%  Inputs:
%  - X (numeric vector, n×1 or 1×n): coordinate vector
%  - Y (numeric vector, n×1 or 1×n): data vector evaluated against threshold
%  - crossingValue (numeric scalar): threshold value to detect
%  - direction (char/string): search direction, 'forward' or 'backward'
%  - signDir (char/string): crossing sign, 'positive' or 'negative'
%
%  Outputs:
%  - xCross (double scalar): X coordinate of detected crossing point
%  - yCross (double scalar): Y value of detected crossing point
%  - idxCross (double scalar): index of detected crossing point

%% =========================
%  Usage
%  =========================
%  Example:
%  [xCross, yCross, idxCross] = findCrossing(X, Y, crossingValue, 'forward', 'positive');

%% =========================
%  Parameters
%  =========================
%  - direction: defines whether the search starts from the first or last element
%  - signDir: defines whether the detected crossing is below-to-above or above-to-below

%% =========================
%  Dependencies
%  =========================
%  - Required toolboxes:
%    MATLAB base environment
%  - External functions/files:
%    None

%% =========================
%  Notes
%  =========================
%  - X and Y must have the same number of elements.
%  - NaN samples are skipped.
%  - Positive crossing means Y changes from below to above crossingValue.
%  - Negative crossing means Y changes from above to below crossingValue.
%  - If no crossing is found, all outputs are returned as NaN.

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


function [xCross, yCross, idxCross] = findCrossing(X, Y, crossingValue, direction, signDir)

if nargin ~= 5
    error('findCrossing requires five inputs: X, Y, crossingValue, direction, signDir.');
end

validateattributes(X, {'numeric'}, {'vector'}, mfilename, 'X', 1);
validateattributes(Y, {'numeric'}, {'vector'}, mfilename, 'Y', 2);

if numel(X) ~= numel(Y)
    error('X and Y must have the same number of elements.');
end

if ~isscalar(crossingValue) || ~isnumeric(crossingValue)
    error('crossingValue must be a numeric scalar.');
end

if ischar(direction) || isstring(direction)
    direction = char(direction);
else
    error('direction must be ''forward'' or ''backward''.');
end

if ischar(signDir) || isstring(signDir)
    signDir = char(signDir);
else
    error('sign must be ''positive'' or ''negative''.');
end

direction = lower(strtrim(direction));
signDir   = lower(strtrim(signDir));

if ~ismember(direction, {'forward','backward'})
    error('direction must be ''forward'' or ''backward''.');
end
if ~ismember(signDir, {'positive','negative'})
    error('sign must be ''positive'' or ''negative''.');
end

X = X(:);
Y = Y(:);
n = numel(Y);

% default outputs: NaN if not found
xCross   = NaN;
yCross   = NaN;
idxCross = NaN;

% choose index iteration based on direction
if strcmp(direction, 'forward')
    idxStart = 1;
    idxEnd   = n;
    step     = 1;
else
    idxStart = n;
    idxEnd   = 1;
    step     = -1;
end

i = idxStart;
while ( (step > 0 && i <= idxEnd) || (step < 0 && i >= idxEnd) )

    % skip NaN samples
    if isnan(X(i)) || isnan(Y(i))
        i = i + step;
        continue;
    end

    % exact match has priority
    if Y(i) == crossingValue
        xCross   = X(i);
        yCross   = Y(i);
        idxCross = i;
        break;
    end

    % neighbour needed for crossing test
    iNext = i + step;
    if iNext < 1 || iNext > n
        i = i + step;
        continue;
    end

    if isnan(X(iNext)) || isnan(Y(iNext))
        i = i + step;
        continue;
    end

    y1 = Y(i);
    y2 = Y(iNext);

    switch signDir
        case 'positive'   % below -> above
            bracket = (y1 < crossingValue) && (y2 > crossingValue);
        case 'negative'   % above -> below
            bracket = (y1 > crossingValue) && (y2 < crossingValue);
        otherwise
            bracket = false;
    end

    if bracket
        xCross   = X(i);
        yCross   = Y(i);
        idxCross = i;
        break;
    end

    i = i + step;
end

end
