function [s_clean, out] = clean_binary_event_pairs(t, s)
% CLEAN_BINARY_EVENT_PAIRS
% Cleans malformed binary event structure:
% - removes unmatched leading offsets
% - removes unmatched trailing onsets
% - keeps only valid onset-offset pairs
% - rebuilds the binary signal on the original timebase

t = double(t(:));
s = logical(s(:));

if numel(t) ~= numel(s)
    error('t and s must have the same length.');
end

% Find raw events
on_idx  = find(diff([false; s]) == 1);
off_idx = find(diff([s; false]) == -1);

raw_on_idx  = on_idx;
raw_off_idx = off_idx;

% Pair events safely
i = 1;
j = 1;
pair_on = [];
pair_off = [];

while i <= numel(on_idx) && j <= numel(off_idx)

    % skip unmatched offset that occurs before the next onset
    if off_idx(j) < on_idx(i)
        j = j + 1;
        continue;
    end

    % valid onset-offset pair
    pair_on(end+1,1)  = on_idx(i); %#ok<AGROW>
    pair_off(end+1,1) = off_idx(j); %#ok<AGROW>

    i = i + 1;
    j = j + 1;
end

% Rebuild clean signal
s_clean = false(size(s));
for k = 1:numel(pair_on)
    s_clean(pair_on(k):pair_off(k)) = true;
end

% Output
out.raw.n_on  = numel(raw_on_idx);
out.raw.n_off = numel(raw_off_idx);
out.raw.t_on  = t(raw_on_idx);
out.raw.t_off = t(raw_off_idx);

out.clean.n_events = numel(pair_on);
out.clean.n_on  = numel(pair_on);
out.clean.n_off = numel(pair_off);
out.clean.t_on  = t(pair_on);
out.clean.t_off = t(pair_off);
out.clean.dur_on = t(pair_off) - t(pair_on);

out.removed.leading_offsets = out.raw.n_off - numel(pair_off);
out.removed.trailing_onsets = out.raw.n_on - numel(pair_on);

fprintf('Raw on/off:   %d / %d\n', out.raw.n_on, out.raw.n_off);
fprintf('Clean on/off: %d / %d\n', out.clean.n_on, out.clean.n_off);
end