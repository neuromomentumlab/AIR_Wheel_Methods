function out = extract_led_from_roi_M(T, fps, varargin)
% extract_led_from_roi_M
%
% Extract LED ON/OFF signal from CSV and compare MATLAB vs Python results
%
% INPUTS
%   T    : table from *_LED_signal.csv
%   fps  : frames per second
%
% OUTPUT
%   out.time
%   out.signal_raw
%   out.signal_s
%   out.is_on
%   out.thresholds

% -------------------------------
% Parse inputs
% -------------------------------
p = inputParser;

addRequired(p,'T');
addRequired(p,'fps',@(x) isnumeric(x) && x>0);

addParameter(p,'MedianWindow',7);
addParameter(p,'MinDuration',0.2);

parse(p,T,fps,varargin{:});

w        = p.Results.MedianWindow;
minDur_s = p.Results.MinDuration;

% -------------------------------
% Time vector
% -------------------------------
if ismember('time_sec',T.Properties.VariableNames)
    time = T.time_sec;
elseif ismember('time_s',T.Properties.VariableNames)
    time = T.time_s;
else
    time = double(T.frame) / fps;
end

if ismember('times_ms',T.Properties.VariableNames)
    time_ms = T.times_ms;
end

% -------------------------------
% Choose LED signal
% -------------------------------
if ismember('corr_signal',T.Properties.VariableNames)

    sig_raw = double(T.corr_signal);

elseif ismember('red_strength',T.Properties.VariableNames)

    sig_raw = double(T.red_strength);

elseif ismember('mean_red',T.Properties.VariableNames)

    sig_raw = double(T.mean_red);

else
    error('No usable LED signal column found.');
end

% -------------------------------
% Smooth signal
% -------------------------------
sig_s = movmedian(sig_raw, w);

% -------------------------------
% Threshold detection
% -------------------------------
if ismember('threshold_on',T.Properties.VariableNames)

    thr_on  = unique(T.threshold_on);
    thr_off = unique(T.threshold_off);

    thr_on  = thr_on(1);
    thr_off = thr_off(1);

else
    lo = prctile(sig_s,20);
    hi = prctile(sig_s,80);

    thr_on  = lo + 0.6*(hi-lo);
    thr_off = lo + 0.4*(hi-lo);
end

% -------------------------------
% Hysteresis binarization
% -------------------------------
is_on = false(size(sig_s));
state = false;

for i = 1:numel(sig_s)

    if ~state && sig_s(i) >= thr_on
        state = true;

    elseif state && sig_s(i) <= thr_off
        state = false;
    end

    is_on(i) = state;

end

% -------------------------------
% Remove glitches
% -------------------------------
minSamples = round(minDur_s * fps);

is_on = bwareaopen(is_on,minSamples);
is_on = ~bwareaopen(~is_on,minSamples);

py_led = strcmpi(T.LED_on,'True');
out.is_onP = py_led;

% -------------------------------
% Output
% -------------------------------
out.time        = time;
out.signal_raw  = sig_raw;
out.signal_s    = sig_s;
out.is_on       = is_on;
out.thresholds  = [thr_off thr_on];

% ==========================================================
% Python vs MATLAB comparison
% ==========================================================

if ismember('LED_on',T.Properties.VariableNames)

    py_led = T.LED_on;

    if iscell(py_led)
    
        % Convert 'True'/'False' strings to logical
        py_led = strcmpi(py_led,'true') | strcmpi(py_led,'1');
    
    elseif isstring(py_led)
    
        py_led = strcmpi(py_led,"true") | strcmpi(py_led,"1");
    
    else
    
        py_led = logical(py_led);
    
    end
    matlab_led = logical(is_on);

    if numel(py_led) == numel(matlab_led)

        diff_idx = find(py_led ~= matlab_led);
        n_diff = numel(diff_idx);

        fprintf('--------------------------------------\n');
        fprintf('Python vs MATLAB LED comparison\n');
        fprintf('Total frames: %d\n', numel(py_led));
        fprintf('Mismatched frames: %d\n', n_diff);

        if n_diff > 0
            fprintf('First mismatches at frames:\n');
            disp(diff_idx(1:min(10,n_diff)));

            warning('MATLAB LED signal differs from Python LED detection.');
        else
            fprintf('Signals match perfectly.\n');
        end

        fprintf('--------------------------------------\n');

    else

        warning('Python and MATLAB LED vectors have different lengths.');

    end

end

end