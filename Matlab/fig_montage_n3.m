function fig_montage

% vp = evalin('base','vp');
% vf = evalin('base','vf');
% v = evalin('base','v');
mD = evalin('base','mData'); colors = mD.colors; sigColor = mD.sigColor; axes_font_size = mD.axes_font_size;
mData = mD;
animal = evalin('base','animal');
n = 0;
%%

streams = ["paws","face","pupil"];

% pooled storage
S_all = struct();

for f = ["daq","paws","face","pupil"]
    S_all.(f).on  = [];
    S_all.(f).off = [];
end

num_animals = length(animal);

for a = 1:num_animals

    % --- durations ---
    [dur_daq, ~, ~, dur_daq_off] = ...
        air_durations(animal(a).b.t, animal(a).b.air_bin);

    [dur_paws, ~, ~, dur_paws_off] = ...
        air_durations(animal(a).b.led_sig.paws.time, ...
                      animal(a).b.led_sig.paws.is_on);

    [dur_face, ~, ~, dur_face_off] = ...
        air_durations(animal(a).b.led_sig.face.time, ...
                      animal(a).b.led_sig.face.is_on);

    [dur_pupil, ~, ~, dur_pupil_off] = ...
        air_durations(animal(a).b.led_sig.pupil.time, ...
                      animal(a).b.led_sig.pupil.is_on);

    % --- trim to common trial count per animal ---
    N_on = min([numel(dur_daq), numel(dur_paws), ...
                numel(dur_face), numel(dur_pupil)]);

    N_off = min([numel(dur_daq_off), numel(dur_paws_off), ...
                 numel(dur_face_off), numel(dur_pupil_off)]);

    % --- append pooled ---
    S_all.daq.on   = [S_all.daq.on;   dur_daq(1:N_on)];
    S_all.daq.off  = [S_all.daq.off;  dur_daq_off(1:N_off)];

    S_all.paws.on  = [S_all.paws.on;  dur_paws(1:N_on)];
    S_all.paws.off = [S_all.paws.off; dur_paws_off(1:N_off)];

    S_all.face.on  = [S_all.face.on;  dur_face(1:N_on)];
    S_all.face.off = [S_all.face.off; dur_face_off(1:N_off)];

    S_all.pupil.on  = [S_all.pupil.on;  dur_pupil(1:N_on)];
    S_all.pupil.off = [S_all.pupil.off; dur_pupil_off(1:N_off)];

    fprintf('Animal %d durations added\n',a);
end

E = struct();

for s = streams
    E.(s).on_ms  = 1000*(S_all.(s).on  - S_all.daq.on);
    E.(s).off_ms = 1000*(S_all.(s).off - S_all.daq.off);
end

figure('Color','w');
tiledlayout(1,2,'Padding','compact','TileSpacing','tight');

streams = ["paws","face","pupil"];
colors = lines(numel(streams));

% =========================
% ON jitter
% =========================
nexttile; hold on;

for i = 1:numel(streams)
    s = streams(i);
    
    x = i + 0.1*randn(size(E.(s).on_ms));
    scatter(x, E.(s).on_ms, 15, colors(i,:), 'filled', ...
        'MarkerFaceAlpha',0.4);
end

yline(0,'k--');
xlim([0.5 3.5])
set(gca,'XTick',1:3,'XTickLabel',upper(streams))
ylabel('ON duration error (ms)')
title('LED timing jitter (ON)')
box off; format_axes(gca);

% =========================
% OFF jitter
% =========================
nexttile; hold on;

for i = 1:numel(streams)
    s = streams(i);
    
    x = i + 0.1*randn(size(E.(s).off_ms));
    scatter(x, E.(s).off_ms, 15, colors(i,:), 'filled', ...
        'MarkerFaceAlpha',0.4);
end

yline(0,'k--');
xlim([0.5 3.5])
set(gca,'XTick',1:3,'XTickLabel',upper(streams))
ylabel('OFF duration error (ms)')
title('LED timing jitter (OFF)')
box off; format_axes(gca);

%%

fs_cam = 60;   % camera frame rate (Hz)
streams = ["paws","face","pupil"];
num_animals = length(animal);

FrameErr = struct();

for s = streams
    FrameErr.(s).on_frames  = [];
    FrameErr.(s).off_frames = [];
    FrameErr.(s).on_ms  = [];
    FrameErr.(s).off_ms = [];
end

for a = 1:num_animals

    % --- DAQ durations ---
    [dur_daq_on, ~, ~, dur_daq_off] = ...
        air_durations(animal(a).b.t, animal(a).b.air_bin);

    for s = streams

        % --- LED durations ---
        [dur_led_on, ~, ~, dur_led_off] = ...
            air_durations(animal(a).b.led_sig.(s).time, ...
                          animal(a).b.led_sig.(s).is_on);

        % --- match trial counts ---
        N_on  = min(numel(dur_daq_on),  numel(dur_led_on));
        N_off = min(numel(dur_daq_off), numel(dur_led_off));

        daq_on  = dur_daq_on(1:N_on);
        led_on  = dur_led_on(1:N_on);

        daq_off = dur_daq_off(1:N_off);
        led_off = dur_led_off(1:N_off);

        % ============================================
        % ⭐ FRAME COUNT ANALYSIS (what reviewer wants)
        % ============================================

        % expected frames from DAQ
        expected_on_frames  = daq_on  * fs_cam;
        expected_off_frames = daq_off * fs_cam;

        % observed frames from LED
        observed_on_frames  = led_on  * fs_cam;
        observed_off_frames = led_off * fs_cam;

        % frame error
        err_on_frames  = observed_on_frames  - expected_on_frames;
        err_off_frames = observed_off_frames - expected_off_frames;

        % ms equivalent
        err_on_ms  = err_on_frames  * (1000/fs_cam);
        err_off_ms = err_off_frames * (1000/fs_cam);

        % --- store pooled ---
        FrameErr.(s).on_frames  = [FrameErr.(s).on_frames;  err_on_frames(:)];
        FrameErr.(s).off_frames = [FrameErr.(s).off_frames; err_off_frames(:)];

        FrameErr.(s).on_ms  = [FrameErr.(s).on_ms;  err_on_ms(:)];
        FrameErr.(s).off_ms = [FrameErr.(s).off_ms; err_off_ms(:)];
    end

    fprintf('Frame analysis complete for animal %d\n',a);
end


fprintf('\n=== FRAME COUNT ERROR SUMMARY ===\n');

for s = streams

    mu_on  = mean(FrameErr.(s).on_frames);
    sd_on  = std(FrameErr.(s).on_frames);
    max_on = max(abs(FrameErr.(s).on_frames));

    mu_off  = mean(FrameErr.(s).off_frames);
    sd_off  = std(FrameErr.(s).off_frames);
    max_off = max(abs(FrameErr.(s).off_frames));

    fprintf('\n%s:\n', upper(s));
    fprintf('  ON  frame error: mean = %+5.2f, SD = %5.2f, max = %5.2f frames\n', ...
        mu_on, sd_on, max_on);
    fprintf('  OFF frame error: mean = %+5.2f, SD = %5.2f, max = %5.2f frames\n', ...
        mu_off, sd_off, max_off);
end

figure('Color','w');
tiledlayout(1,2,'Padding','compact','TileSpacing','tight');

colors = lines(numel(streams));

% ======================
% ON frame error
% ======================
nexttile; hold on;

for i = 1:numel(streams)
    s = streams(i);
    x = i + 0.08*randn(size(FrameErr.(s).on_frames));
    scatter(x, FrameErr.(s).on_frames, 12, colors(i,:), ...
        'filled','MarkerFaceAlpha',0.4);
end

yline(0,'k--');
ylabel('Frame error (frames)')
title('Air-ON frame error')
set(gca,'XTick',1:3,'XTickLabel',upper(streams))
box off; format_axes(gca);

% ======================
% OFF frame error
% ======================
nexttile; hold on;

for i = 1:numel(streams)
    s = streams(i);
    x = i + 0.08*randn(size(FrameErr.(s).off_frames));
    scatter(x, FrameErr.(s).off_frames, 12, colors(i,:), ...
        'filled','MarkerFaceAlpha',0.4);
end

yline(0,'k--');
ylabel('Frame error (frames)')
title('Air-OFF frame error')
set(gca,'XTick',1:3,'XTickLabel',upper(streams))
box off; format_axes(gca);


max(abs(FrameErr.(s).on_frames))
max(abs(FrameErr.(s).off_frames))





function [durations, on_t, off_t, durationsoff] = air_durations(t, air_bin)
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

