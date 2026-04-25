function animal = load_led_signal(animal,suffix)

if ~exist('animal','var')
    animal = evalin('base','animal');
end

if ~exist('owr','var')
    owr = 0;
end

cams = {'face','pupil','paws'};

for an = 1:numel(animal)

    if ~isfield(animal(an),'video') || ~isfield(animal(an).video,'h264')
        continue;
    end

    for c = 1:numel(cams)

        cam = cams{c};

        if ~isfield(animal(an).video.h264, cam)
            continue;
        end

        in_file = animal(an).video.h264.(cam);

        if isempty(in_file) || ~exist(in_file,'file')
            warning('process_h264:FileNotFound','Missing %s',in_file);
            continue;
        end

        [~,base,~] = fileparts(in_file);
        csv_name = [base sprintf('_%s.csv',suffix)];
        out_file_csv = fullfile(animal(an).pdir, csv_name);
        if ~exist(out_file_csv, 'file')
            loc_R = strfind(out_file_csv,'_R');
            out_file_csv(loc_R:(loc_R+1)) = [];
        end
        disp(out_file_csv);
        animal(an).video.led.(cam) = out_file_csv;

        fps = animal(an).video.specs.(cam).fps;
        tbl = readtable(out_file_csv);
        animal(an).b.led.(cam) = tbl;
        t_daq = animal(an).b.t; s_daq = animal(an).b.air_bin';
        % [s_daq,~] = clean_binary_event_pairs(t_daq,s_daq);
        if strcmp(suffix,'LED_signal')
            t_led = tbl.frame/fps; %s_led = strcmp(tbl.LED_on,'True');
            s_led_raw = tbl.signal_raw;
            s_led = apply_binary_segmentation(t_led,s_led_raw);
            [s_led,~] = validate_led_signal(t_daq,s_daq,t_led,s_led);
            if an == 4 && strcmp(cam,'paws')
                csv_name_B = [base sprintf('_%s_B.csv',suffix)];
                out_file_csv_B = fullfile(animal(an).pdir, csv_name_B);
                tbl_B = readtable(out_file_csv_B);
                s_led_raw_B = tbl_B.signal_raw;
                s_led_B = apply_binary_segmentation(t_led,s_led_raw_B);
                s_led_bin = binarize_led_with_background(t_led,s_led_raw,s_led_raw_B,'Plot',false);
                [s_led,~] = validate_led_signal(t_daq,s_daq,t_led,s_led_bin);
                [s_daq, ~] = remove_event_from_binary(t_daq, s_daq, 54);
                n = 0;
            end
        else
            t_led = tbl.frame/fps; s_led = strcmp(tbl.is_on,'True');
        end
        if an == 4 && (strcmp(cam,'face') || strcmp(cam,'pupil'))
            [s_led, ~] = remove_event_from_binary(t_led, s_led, 54);
            [s_daq, ~] = remove_event_from_binary(t_daq, s_daq, 54);
            n = 0;
        end

        % figure(100); clf; plot_binary_with_event_numbers(t_daq, 0.5*s_daq, 100,'b',0.5); hold on; plot_binary_with_event_numbers(t_led, s_led, 100, 'r', 0.95); xlabel('Time (s)'); ylabel('State');
        % figure(100); clf; plot_binary_with_event_numbers(t_daq, 0.5*s_daq, 100,'b',0.5); hold on; plot_binary_with_event_numbers(t_led, s_led_clean, 100, 'r', 0.95); xlabel('Time (s)'); ylabel('State');
        animal(an).b.led_sig.(cam).t_led = t_led;
        animal(an).b.led_sig.(cam).is_on = s_led;
        n = 0;
    end
end
end

function [s_out, out] = merge_events_in_binary(t, s, eventNum1, eventNum2)
% MERGE_EVENTS_IN_BINARY
% Fills the gap between two events to combine them into one.
%
% INPUTS
%   t         : time vector
%   s         : binary/logical waveform
%   eventNum1 : First event index (1-based)
%   eventNum2 : Second event index (usually eventNum1 + 1)

    t = double(t(:));
    s = logical(s(:));

    % 1. Find the onset/offset pairs using your existing pairing logic
    on_idx_raw  = find(diff([false; s]) == 1);
    off_idx_raw = find(diff([s; false]) == -1);
    [on_idx_p, off_idx_p] = local_pair_events(on_idx_raw, off_idx_raw);

    nEvents = numel(on_idx_p);
    if eventNum1 > nEvents || eventNum2 > nEvents
        error('Event numbers exceed total detected events (%d)', nEvents);
    end

    % 2. Identify the gap to fill
    % We need to fill from the END of the earlier event 
    % to the START of the later event.
    idx_start_fill = min(off_idx_p(eventNum1), off_idx_p(eventNum2));
    idx_end_fill   = max(on_idx_p(eventNum1), on_idx_p(eventNum2));

    % 3. Create output signal and fill the gap
    s_out = s;
    s_out(idx_start_fill:idx_end_fill) = true;

    % 4. Output info for verification
    out.merged_indices = [eventNum1, eventNum2];
    out.gap_time_range = [t(idx_start_fill), t(idx_end_fill)];
    
    % Recalculate final events for the 'after' struct
    on_idx_new  = find(diff([false; s_out]) == 1);
    off_idx_new = find(diff([s_out; false]) == -1);
    [out.after.on_idx, out.after.off_idx] = local_pair_events(on_idx_new, off_idx_new);
    out.after.nEvents = numel(out.after.on_idx);
end

function [s_out, out] = remove_event_from_binary(t, s, eventNum)
% REMOVE_EVENT_FROM_BINARY
% Remove one ON event (onset-offset pair) from a binary waveform.
%
% INPUTS
%   t        : time vector
%   s        : binary/logical waveform
%   eventNum : event number to remove (1-based)
%
% OUTPUTS
%   s_out    : binary waveform with selected event removed
%   out      : struct with event info before/after
%
% NOTES
% - Events are defined as onset-offset pairs
% - Unmatched leading offsets / trailing onsets are ignored automatically
% - The function preserves the original sampling and timebase

    t = double(t(:));
    s = logical(s(:));

    if numel(t) ~= numel(s)
        error('t and s must have the same length.');
    end

    % ---------------------------------
    % Find raw onsets and offsets
    % ---------------------------------
    on_idx  = find(diff([false; s]) == 1);
    off_idx = find(diff([s; false]) == -1);

    t_on  = t(on_idx);
    t_off = t(off_idx);

    % ---------------------------------
    % Build valid onset-offset pairs
    % ---------------------------------
    [on_keep_idx, off_keep_idx] = local_pair_events(on_idx, off_idx);

    on_idx_p  = on_keep_idx;
    off_idx_p = off_keep_idx;

    t_on_p  = t(on_idx_p);
    t_off_p = t(off_idx_p);

    nEvents = numel(on_idx_p);

    if nEvents == 0
        warning('No valid events found.');
        s_out = s;
        out = struct();
        return;
    end

    if eventNum < 1 || eventNum > nEvents
        error('eventNum must be between 1 and %d.', nEvents);
    end

    % ---------------------------------
    % Remove selected event
    % ---------------------------------
    keepMask = true(nEvents,1);
    keepMask(eventNum) = false;

    on_idx_new  = on_idx_p(keepMask);
    off_idx_new = off_idx_p(keepMask);

    % ---------------------------------
    % Rebuild waveform
    % ---------------------------------
    s_out = false(size(s));

    for k = 1:numel(on_idx_new)
        s_out(on_idx_new(k):off_idx_new(k)) = true;
    end

    % ---------------------------------
    % Output info
    % ---------------------------------
    out.before.on_idx = on_idx_p;
    out.before.off_idx = off_idx_p;
    out.before.t_on = t_on_p;
    out.before.t_off = t_off_p;
    out.before.nEvents = nEvents;

    out.removed.eventNum = eventNum;
    out.removed.on_idx = on_idx_p(eventNum);
    out.removed.off_idx = off_idx_p(eventNum);
    out.removed.t_on = t_on_p(eventNum);
    out.removed.t_off = t_off_p(eventNum);

    out.after.on_idx = on_idx_new;
    out.after.off_idx = off_idx_new;
    out.after.t_on = t(on_idx_new);
    out.after.t_off = t(off_idx_new);
    out.after.nEvents = numel(on_idx_new);

end

function [on_idx_p, off_idx_p] = local_pair_events(on_idx, off_idx)
% Pair onsets and offsets in order, skipping invalid leading/trailing events

    i = 1;
    j = 1;

    on_idx_p = [];
    off_idx_p = [];

    while i <= numel(on_idx) && j <= numel(off_idx)

        if off_idx(j) < on_idx(i)
            % unmatched leading offset -> skip
            j = j + 1;
            continue;
        end

        % now off_idx(j) >= on_idx(i)
        on_idx_p(end+1,1) = on_idx(i); %#ok<AGROW>
        off_idx_p(end+1,1) = off_idx(j); %#ok<AGROW>

        i = i + 1;
        j = j + 1;
    end

end


function out = plot_binary_with_event_numbers(t, s, figNum, lineSpec, yText)
% PLOT_BINARY_WITH_EVENT_NUMBERS
% Plot binary waveform and label each onset-offset event with its number.
%
% INPUTS
%   t       : time vector
%   s       : binary/logical signal
%   figNum  : figure number (optional)
%   lineSpec: plot style, e.g. 'r', 'b', 'k' (optional)
%   yText   : vertical position for labels (optional, default = 0.9)
%
% OUTPUT
%   out     : struct with onset/offset indices and times

    if nargin < 3 || isempty(figNum), figNum = gcf; end
    if nargin < 4 || isempty(lineSpec), lineSpec = 'b'; end
    if nargin < 5 || isempty(yText), yText = 0.9; end

    t = double(t(:));
    s = logical(s(:));

    on_idx  = find(diff([false; s]) == 1);
    off_idx = find(diff([s; false]) == -1);

    [on_idx_p, off_idx_p] = local_pair_events(on_idx, off_idx);

    t_on  = t(on_idx_p);
    t_off = t(off_idx_p);
    dur = t_off - t_on;

    figure(figNum); hold on;
    plot(t, s, lineSpec, 'LineWidth', 1.5);

    for k = 1:numel(t_on)
        xm = (t_on(k) + t_off(k)) / 2;
        text(xm, yText, sprintf('%d', k), ...
            'Color', lineSpec(1), ...
            'FontSize', 8, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontWeight', 'bold');

        text(xm, yText-0.2, sprintf('%.1f', dur(k)), ...
            'Color', lineSpec(1), ...
            'FontSize', 8, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontWeight', 'bold');
    end

    out.on_idx = on_idx_p;
    out.off_idx = off_idx_p;
    out.t_on = t_on;
    out.t_off = t_off;
    out.nEvents = numel(t_on);

end
