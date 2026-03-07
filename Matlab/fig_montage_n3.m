function fig_montage

% vp = evalin('base','vp');
% vf = evalin('base','vf');
% v = evalin('base','v');
mD = evalin('base','mData'); colors = mD.colors; sigColor = mD.sigColor; axes_font_size = mD.axes_font_size;
mData = mD;
animals = evalin('base','animals');
animal = animals(3:5);
animal = animals(1); fs_cam = 45;   % camera frame rate (Hz)
% animal = animals(2); fs_cam = 60;   % camera frame rate (Hz)
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

hf = figure(100);
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
        % ⭐ FRAME COUNT ANALYSIS
        % ============================================

        % expected frames from DAQ
        expected_on_frames  = daq_on  * fs_cam;
        expected_off_frames = daq_off * fs_cam;

        % observed frames from LED
        observed_on_frames  = led_on  * animal.video.specs.(s).fps;
        observed_off_frames = led_off * animal.video.specs.(s).fps;

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

figure(100);
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
%%
%% ============================================================
% Event-anchored timing divergence without video upsampling
% Separate analysis for LED ON and LED OFF
%% ============================================================
close all
magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 6.8 1.5],'RowsCols',[2 3],'spaceRowsCols',[0.25 -0.02],'rightUpShifts',[0.15 0.2],...
    'widthHeightAdjustment',[0 -285]);
MY = 2; ysp = 0.15285; mY = -2.5; titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80
stp = 0.325*magfac; widths = [1.9 1.9 1.9 1]*magfac; gap = 0.3*magfac;
adjust_axes(ff,[mY MY],stp,widths,gap,{''});
axes_title_shifts_line = [0 0.55 0 0]; axes_title_shifts_text = [0.02 0.1 0 0]; xs_gaps = [1 2];

window = 3;   % seconds
cams = {'paws','face','pupil'};
camsT = {'Paws','Face','Pupil'};

% DAQ signals
t_daq   = animal(1).b.t;
air_daq = animal(1).b.air_bin;

[~, t_on_daq, t_off_daq] = air_durations(t_daq, air_daq);

for c = 1:length(cams)

    cam = cams{c};

    % Video signals
    t_vid   = animal(1).b.led_sig.(cam).time;
    led_vid = animal(1).b.led_sig.(cam).is_on;

    [~, t_on_vid, t_off_vid] = air_durations(t_vid, led_vid);

    % Effective fps from timestamps
    fps_eff = 1 / median(diff(t_vid));

    % ---------------------------
    % Helper function idea inline:
    % compute divergence around events
    % ---------------------------

    event_sets = {
        'ON',  t_on_daq,  t_on_vid;
        'OFF', t_off_daq, t_off_vid
    };

    % figure('Name',['Timing divergence: ' cam], 'Color','w');

    for e = 1:2

        label     = event_sets{e,1};
        evt_daq   = event_sets{e,2};
        evt_vid   = event_sets{e,3};

        nEvents = min(length(evt_daq), length(evt_vid));

        div_cells = cell(nEvents,1);
        tau_cells = cell(nEvents,1);

        for i = 1:nEvents

            % Anchor event at zero
            tau_daq = t_daq - evt_daq(i);
            tau_vid = t_vid - evt_vid(i);

            % Keep only ± window for video frames
            idx_vid = abs(tau_vid) <= window;
            tau_vid_local = tau_vid(idx_vid);

            % For each video frame time, find nearest DAQ sample
            idx_nearest = interp1(tau_daq, 1:length(tau_daq), tau_vid_local, 'nearest', 'extrap');
            idx_nearest = max(1, min(length(tau_daq), round(idx_nearest)));

            tau_daq_nearest = tau_daq(idx_nearest);

            % Divergence = video-relative time - DAQ-relative time
            div_local = tau_vid_local - tau_daq_nearest;

            tau_cells{i} = tau_vid_local(:);
            div_cells{i} = div_local(:);
        end

        % Build common time grid on video scale
        dt = median(diff(t_vid));
        tau_grid = (-window:dt:window)';

        div_mat = nan(length(tau_grid), nEvents);

        for i = 1:nEvents
            div_mat(:,i) = interp1(tau_cells{i}, div_cells{i}, tau_grid, 'linear', nan);
        end

        mean_div = mean(div_mat, 2, 'omitnan');
        std_div  = std(div_mat, 0, 2, 'omitnan');

        frame_err = mean_div * fps_eff;

        % Plot in ms
        % subplot(2,1,e)
        axes(ff.h_axes(e,c));
        if e == 1
            setcolor = 'r';
        else
            setcolor = 'b';
        end
        plot(tau_grid, mean_div* fps_eff, setcolor, 'LineWidth', 0.5); hold on
        plot(tau_grid, (mean_div+std_div)* fps_eff, '-', 'Color', [0.5 0.5 0.5],'LineWidth',0.25);
        plot(tau_grid, (mean_div-std_div)* fps_eff, '-', 'Color', [0.5 0.5 0.5],'LineWidth',0.25);
        yline(0, ':');
        xline(0, ':r');
        if e == 2
            xlabel(['Time from Event (s)']);
        end
        % ylim([-0.01 0.01])
        if c == 1
            ylabel('Frame error (#)');
        else
            % set(gca,'YTickLabel',[])
        end
        if e == 1
            title([camsT{c} ' Video']);
        end
        grid on
        format_axes(gca)

        % Print summary
        fprintf('\nCamera: %s | Event: %s\n', cam, label);
        fprintf('Max abs timing error within ±%d s: %.3f ms\n', ...
            window, max(abs(mean_div))*1000);
        fprintf('Max abs frame error within ±%d s: %.3f frames\n', ...
            window, max(abs(frame_err)));
    end
end
save_pdf(ff.hf,mData.pdf_folder,'alignment_error.pdf',600);
