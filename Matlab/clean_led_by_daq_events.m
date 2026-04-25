function [s_led_clean, out] = clean_led_by_daq_events(t_daq, s_daq, t_led, s_led, varargin)
% CLEAN_LED_BY_DAQ_EVENTS
% Repairs a binarized LED signal using DAQ signal as ground truth.
%
% Main idea:
%   For each DAQ ON event, keep LED = 1 only inside the matching DAQ event window.
%   This removes extra LED events and merges split LED events.
%
% Inputs:
%   t_daq, s_daq : DAQ time and binary DAQ signal
%   t_led, s_led : LED time and binary LED signal
%
% Optional:
%   'PadSec'     : time padding around each DAQ event window, default 0.25 s
%   'MinOverlap' : minimum number of LED frames inside a DAQ window, default 1
%   'Verbose'    : true/false, default true

p = inputParser;
addParameter(p, 'PadSec', 0.25);
addParameter(p, 'MinOverlap', 1);
addParameter(p, 'Verbose', true);
parse(p, varargin{:});

padSec     = p.Results.PadSec;
minOverlap = p.Results.MinOverlap;
verbose    = p.Results.Verbose;

t_daq = double(t_daq(:));
s_daq = logical(s_daq(:));
t_led = double(t_led(:));
s_led = logical(s_led(:));

daq = get_events(t_daq, s_daq);
led_before = get_events(t_led, s_led);

s_led_clean = false(size(s_led));

matched_led_frames = cell(numel(daq.t_on),1);
daq_has_led = false(numel(daq.t_on),1);

for k = 1:numel(daq.t_on)

    win_start = daq.t_on(k)  - padSec;
    win_end   = daq.t_off(k) + padSec;

    idx_win = t_led >= win_start & t_led <= win_end;

    idx_led_on_in_win = idx_win & s_led;

    if nnz(idx_led_on_in_win) >= minOverlap
        s_led_clean(idx_win) = true;
        daq_has_led(k) = true;
        matched_led_frames{k} = find(idx_led_on_in_win);
    end
end

led_after = get_events(t_led, s_led_clean);

out.daq = daq;
out.led_before = led_before;
out.led_after = led_after;
out.daq_has_led = daq_has_led;
out.missing_daq_events = find(~daq_has_led);
out.padSec = padSec;
out.minOverlap = minOverlap;

if verbose
    fprintf('\n=====================================\n');
    fprintf('clean_led_by_daq_events\n');
    fprintf('-------------------------------------\n');
    fprintf('DAQ events        : %d\n', daq.n_on);
    fprintf('LED before events : %d\n', led_before.n_on);
    fprintf('LED after events  : %d\n', led_after.n_on);
    fprintf('Missing DAQ events: %d\n', numel(out.missing_daq_events));
    fprintf('Pad used          : %.3f s\n', padSec);
    fprintf('=====================================\n\n');
end

end


function info = get_events(t, s)

on_idx  = find(diff([false; s]) == 1);
off_idx = find(diff([s; false]) == -1);

t_on  = t(on_idx);
t_off = t(off_idx);

n_pair = min(numel(t_on), numel(t_off));

t_on_p  = t_on(1:n_pair);
t_off_p = t_off(1:n_pair);

good = t_off_p > t_on_p;

t_on_p  = t_on_p(good);
t_off_p = t_off_p(good);

info.n_on = numel(t_on_p);
info.n_off = numel(t_off_p);
info.on_idx = on_idx;
info.off_idx = off_idx;
info.t_on = t_on_p;
info.t_off = t_off_p;
info.dur_on = t_off_p - t_on_p;

end