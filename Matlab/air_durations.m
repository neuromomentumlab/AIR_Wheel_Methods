function [durations, on_t, off_t, durationsoff, frames, framesoff] = air_durations(t, air_bin)
% Compute air-on durations from a binary air signal

air_bin = air_bin(:) > 0;
t       = t(:);

d = diff([0; air_bin; 0]);

on_idx  = find(d == 1);
off_idx = find(d == -1) - 1;

n = min(numel(on_idx), numel(off_idx));
on_idx  = on_idx(1:n);
off_idx = off_idx(1:n);

on_t  = t(on_idx);
off_t = t(off_idx);

durations = off_t - on_t;
durationsoff = on_t(2:end) - off_t(1:(end-1));

frames = off_idx - on_idx + 1;
framesoff = on_idx(2:end) - off_idx(1:(end-1));

