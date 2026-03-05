function out = extract_led_from_roi_M(T, fps, varargin)
% extract_led_from_roi (UPDATED FOR video*.csv)
%
% Extract LED ON/OFF signal from processed video intensity CSV
%
% INPUTS
%   T    : table from video*_intensity.csv
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
if ismember('time_s',T.Properties.VariableNames)
    time = T.time_s;
else
    time = double(T.frame) / fps;
end

% -------------------------------
% LED signal
% -------------------------------
sig_raw = double(T.corr_signal);

% smoothing
sig_s = movmedian(sig_raw, w);

% -------------------------------
% Thresholds
% -------------------------------
if ismember('led_threshold_on',T.Properties.VariableNames)

    thr_on  = unique(T.led_threshold_on);
    thr_off = unique(T.led_threshold_off);

    thr_on  = thr_on(1);
    thr_off = thr_off(1);

else
    % fallback adaptive thresholds
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

% -------------------------------
% Output
% -------------------------------
out.time        = time;
out.signal_raw  = sig_raw;
out.signal_s    = sig_s;
out.is_on       = is_on;
out.thresholds  = [thr_off thr_on];

end