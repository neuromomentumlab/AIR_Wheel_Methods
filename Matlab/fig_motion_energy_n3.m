function fig_motion_energy()


% vp = evalin('base','vp');
% vf = evalin('base','vf');
% v = evalin('base','v');
mD = evalin('base','mData'); colors = mD.colors; sigColor = mD.sigColor; axes_font_size = mD.axes_font_size;
mData = mD;
animal = evalin('base','oanimal');

n = 0;

%%
win_pre  = 2;   % seconds
win_post = 5;   % seconds
fs = 60;

Npre  = round(win_pre  * fs);
Npost = round(win_post * fs);

targets = {'pupil'};
num_animals = length(animal);

animal_means = [];   % will store per-animal averages

for a = 1:num_animals
    
    entry = animal(a);
    pdir = entry.pdir;
    
    key = targets{1};   % assuming paws only
    
    % -----------------------------
    % Load LED signal (animal-specific)
    % -----------------------------
    T = entry.b.led_sig.(key);
    air_sig = double(T.is_on);
    
    onsets = find_rising_edge(air_sig,0.5,-1);
    
    % -----------------------------
    % Load optical flow CSV
    % -----------------------------
    if isfield(entry.video.mp4, key)
        full_mp4_path = entry.video.mp4.(key);
        [~, base_name, ~] = fileparts(full_mp4_path);
        
        csv_path = fullfile(pdir, [base_name, '_reduced_OF.csv']);
        if ~exist(csv_path, 'file')
            csv_path = fullfile(pdir, [base_name, '_OF.csv']);
        end
        
        if ~exist(csv_path,'file')
            warning('CSV not found for animal %d',a);
            continue
        end
        
        data = readtable(csv_path);
        
        % optical flow speed
        speed = sqrt(data.avg_u.^2 + data.avg_v.^2);
        speed = speed * 0.0114 * 60;   % your conversion
    else
        continue
    end
    
    % -----------------------------
    % Extract trials for THIS animal
    % -----------------------------
    trials = [];
    
    for i = 1:length(onsets)
        idx = onsets(i);
        
        if idx > Npre && idx + Npost <= length(speed)
            trials(:,end+1) = speed(idx-Npre : idx+Npost);
        end
    end
    
    % -----------------------------
    % Animal-level mean (CRITICAL)
    % -----------------------------
    if ~isempty(trials)
        animal_mean_trace = mean(trials,2);
        animal_means(:,end+1) = animal_mean_trace;
    end
end

t_evt = linspace(-win_pre, win_post, size(animal_means,1));

grand_mean = mean(animal_means,2);
grand_sem  = std(animal_means,[],2) ./ sqrt(size(animal_means,2));


magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 1.75 1.5],...
    'RowsCols',[1 1],...
    'spaceRowsCols',[0.02 -0.02],...
    'rightUpShifts',[0.15 0.22],...
    'widthHeightAdjustment',[10 -250]);

MY = 2; ysp = 0.15285; mY = -2.5;
stp = 0.3*magfac;
widths = [1.5 1 2.85 1]*magfac;
gap = 0.115*magfac;
adjust_axes(ff,[mY MY],stp,widths,gap,{''});

% --- mean ---
shadedErrorBar(t_evt,grand_mean,grand_sem,{'color',[0, 0.447, 0.741]});hold on
plot(t_evt, grand_mean,'color',[0, 0.447, 0.741], 'LineWidth', 1); 
% % --- SEM ---
% plot(t_evt, grand_mean + grand_sem, '--', 'color',[0, 0.447, 0.741]);
% plot(t_evt, grand_mean - grand_sem, '--', 'color',[0, 0.447, 0.741]);

xlabel('Time from air onset (s)')
ylabel('OF Avg. Speed (cm/s)')
xlim([-2 5.5])

box off
format_axes(gca)

save_pdf(ff.hf,mD.pdf_folder,'OF_air_onset_grand_mean.pdf',600);

%
win_pre  = 2;   % seconds
win_post = 6;   % seconds
fs = 60;

Npre  = round(win_pre  * fs);
Npost = round(win_post * fs);

% targets = {'paws'};
num_animals = length(animal);

animal_means = [];   % will store per-animal offset averages

for a = 1:num_animals
    
    entry = animal(a);
    pdir = entry.pdir;
    key = targets{1};
    
    % -----------------------------
    % Load LED signal
    % -----------------------------
    T = entry.b.led_sig.(key);
    air_sig = double(T.is_on);
    
    offsets = find_falling_edge(air_sig,-0.5,1);
    
    % -----------------------------
    % Load OF data
    % -----------------------------
    if isfield(entry.video.mp4, key)
        
        full_mp4_path = entry.video.mp4.(key);
        [~, base_name, ~] = fileparts(full_mp4_path);
        
        csv_path = fullfile(pdir, [base_name, '_reduced_OF.csv']);
        if ~exist(csv_path,'file')
            csv_path = fullfile(pdir, [base_name, '_OF.csv']);
        end
        
        if ~exist(csv_path,'file')
            warning('CSV not found for animal %d',a);
            continue
        end
        
        data = readtable(csv_path);
        
        speed = sqrt(data.avg_u.^2 + data.avg_v.^2);
        speed = speed * 0.0114 * 60;
        
    else
        continue
    end
    
    % -----------------------------
    % Extract trials (OFFSET-aligned)
    % -----------------------------
    trials = [];
    
    for i = 1:length(offsets)
        idx = offsets(i);
        
        if idx > Npre && idx + Npost <= length(speed)
            trials(:,end+1) = speed(idx-Npre : idx+Npost);
        end
    end
    
    % -----------------------------
    % Animal-level mean
    % -----------------------------
    if ~isempty(trials)
        animal_mean_trace = mean(trials,2);
        animal_means(:,end+1) = animal_mean_trace;
    end
end

t_evt = linspace(-win_pre, win_post, size(animal_means,1));

grand_mean = mean(animal_means,2);
grand_sem  = std(animal_means,[],2) ./ sqrt(size(animal_means,2));


magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 1.75 1.5],...
    'RowsCols',[1 1],...
    'spaceRowsCols',[0.02 -0.02],...
    'rightUpShifts',[0.15 0.22],...
    'widthHeightAdjustment',[10 -250]);

MY = 2; mY = -2.5;
stp = 0.3*magfac;
widths = [1.5 1 2.85 1]*magfac;
gap = 0.115*magfac;
adjust_axes(ff,[mY MY],stp,widths,gap,{''});

% % --- SEM shaded band ---
% fill([t_evt fliplr(t_evt)], ...
%      [grand_mean+grand_sem; flipud(grand_mean-grand_sem)]', ...
%      [0, 0.447, 0.741], ...
%      'FaceAlpha',0.2,'EdgeColor','none'); hold on

% --- mean ---
shadedErrorBar(t_evt,grand_mean,grand_sem,{'color',[0, 0.447, 0.741]});hold on
plot(t_evt, grand_mean, 'color',[0, 0.447, 0.741], 'LineWidth', 1);

xlabel('Time from air offset (s)')
ylabel('OF Avg. Speed (cm/s)')
xlim([-2 win_post+0.5])

box off
format_axes(gca)

save_pdf(ff.hf,mD.pdf_folder,'OF_air_offset_grand_mean.pdf',600);

%%

air_on_all  = [];
air_off_all = [];

num_animals = length(animal);
key = 'pupil';

for a = 1:num_animals
    
    entry = animal(a);
    pdir = entry.pdir;

    % -----------------------------
    % LED signal
    % -----------------------------
    T = entry.b.led_sig.(key);
    air_sig = double(T.is_on);

    onsets  = find_rising_edge(air_sig,0.5,-1);
    offsets = find_falling_edge(air_sig,-0.5,1);

    % -----------------------------
    % Load OF speed
    % -----------------------------
    if isfield(entry.video.mp4, key)
        
        full_mp4_path = entry.video.mp4.(key);
        [~, base_name, ~] = fileparts(full_mp4_path);

        csv_path = fullfile(pdir,[base_name '_reduced_OF.csv']);
        if ~exist(csv_path,'file')
            csv_path = fullfile(pdir,[base_name '_OF.csv']);
        end

        if ~exist(csv_path,'file')
            warning('CSV missing for animal %d',a);
            continue
        end

        data = readtable(csv_path);
        speed = sqrt(data.avg_u.^2 + data.avg_v.^2);
        speed = speed * 0.0114 * 60;

    else
        continue
    end

    % =============================
    % PER-ANIMAL trial means
    % =============================
    nTrials = min(numel(onsets), numel(offsets));

    meanSpeed_ON  = nan(nTrials,1);
    meanSpeed_OFF = nan(nTrials,1);

    for k = 1:nTrials

        % --- ON window ---
        idx_on = onsets(k):offsets(k);
        meanSpeed_ON(k) = mean(speed(idx_on),'omitnan');

        % --- preceding OFF ---
        if k == 1
            idx_off = 1:(onsets(k)-1);
        else
            idx_off = offsets(k-1):(onsets(k)-1);
        end

        meanSpeed_OFF(k) = mean(speed(idx_off),'omitnan');
    end

    % =============================
    % CRITICAL: animal-level mean
    % =============================
    air_on_all(end+1,1)  = mean(meanSpeed_ON,'omitnan');
    air_off_all(end+1,1) = mean(meanSpeed_OFF,'omitnan');

    fprintf('Animal %d processed (%d trials)\n',a,nTrials);
end

data_C = [air_off_all air_on_all];

[within,dvn,xlabels] = make_within_table({'St'},[2]);
dataT = make_between_table({data_C},dvn);

ra = RMA(dataT,within,{0.05,{'hsd'}});
print_for_manuscript(ra)


magfac = mData.magfac;

ff = makeFigureRowsCols(2021,[1 4 1.25 1.5],...
    'RowsCols',[1 1],...
    'spaceRowsCols',[0.07 0],...
    'rightUpShifts',[0.25 0.2],...
    'widthHeightAdjustment',[-550 -280]);

MY = 0.3; ysp = 0.05725; mY = 0;
ystf = 0.057251; ysigf = 0.015;

tcolors = {'c','b'};

[hbs,xdata,mVar,semVar,combs,p,h] = ...
    view_results_rmanova(ff.h_axes(1,1),ra,...
    {'St','hsd',0.05},[1 2],tcolors,...
    [mY MY ysp ystf ysigf],mData);

format_axes(gca);

set(gca,'xcolor','k','ycolor','k',...
    'XTick',xdata,...
    'XTickLabel',{'Air-Off','Air-On'});

xtickangle(30);
ylabel({'Avg. OF Speed (cm/s)'});


x_on  = air_off_all(:);
x_off = air_on_all(:);

hold on

jitter = 0.05;  % small horizontal spread
rng(1);         % reproducible

for i = 1:length(x_on)

    % jittered x positions
    x1 = xdata(1) + jitter;
    x2 = xdata(2) - jitter;

    % connecting line
    plot([x1 x2], [x_on(i) x_off(i)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 0.75);

    % dots
    plot(x1, x_on(i), '.', ...
        'MarkerFaceColor', 'w', ...
        'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5);

    plot(x2, x_off(i), '.', ...
        'MarkerFaceColor', 'w', ...
        'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5);
end


save_pdf(ff.hf,mData.pdf_folder,'bar_graphs_animals.pdf',600);




%
energy_on_all  = [];
energy_off_all = [];

num_animals = length(animal);
% key = 'paws';

for a = 1:num_animals
    
    entry = animal(a);
    pdir = entry.pdir;

    % -----------------------------
    % LED signal
    % -----------------------------
    T = entry.b.led_sig.(key);
    air_sig = double(T.is_on);

    onsets  = find_rising_edge(air_sig,0.5,-1);
    offsets = find_falling_edge(air_sig,-0.5,1);

    % -----------------------------
    % Load motion energy
    % -----------------------------
    if isfield(entry.video.mp4, key)
        
        full_mp4_path = entry.video.mp4.(key);
        [~, base_name, ~] = fileparts(full_mp4_path);

        csv_path = fullfile(pdir,[base_name '_reduced_OF.csv']);
        if ~exist(csv_path,'file')
            csv_path = fullfile(pdir,[base_name '_OF.csv']);
        end

        if ~exist(csv_path,'file')
            warning('CSV missing for animal %d',a);
            continue
        end

        data = readtable(csv_path);
        motion_energy = data.motion_energy;

    else
        continue
    end

    % =============================
    % PER-ANIMAL trial means
    % =============================
    nTrials = min(numel(onsets), numel(offsets));

    meanEnergy_ON  = nan(nTrials,1);
    meanEnergy_OFF = nan(nTrials,1);

    for k = 1:nTrials

        % --- ON window ---
        idx_on = onsets(k):offsets(k);
        meanEnergy_ON(k) = mean(motion_energy(idx_on),'omitnan');

        % --- preceding OFF ---
        if k == 1
            idx_off = 1:(onsets(k)-1);
        else
            idx_off = offsets(k-1):(onsets(k)-1);
        end

        meanEnergy_OFF(k) = mean(motion_energy(idx_off),'omitnan');
    end

    % =============================
    % CRITICAL: animal-level mean
    % =============================
    energy_on_all(end+1,1)  = mean(meanEnergy_ON,'omitnan');
    energy_off_all(end+1,1) = mean(meanEnergy_OFF,'omitnan');

    fprintf('Animal %d processed (%d trials)\n',a,nTrials);
end

data_C = [energy_off_all energy_on_all];

[within,dvn,xlabels] = make_within_table({'St'},[2]);
dataT = make_between_table({data_C},dvn);

ra = RMA(dataT,within,{0.05,{'hsd'}});
print_for_manuscript(ra)


magfac = mData.magfac;
mData = evalin('base','mData');

tcolors = {'m','r'};

ff = makeFigureRowsCols(2020,[10 4 1.25 1.5],...
    'RowsCols',[1 1],...
    'spaceRowsCols',[0.07 0],...
    'rightUpShifts',[0.25 0.2],...
    'widthHeightAdjustment',[-550 -280]);

MY = 5; ysp = 0.925; mY = 0;
ystf = 0.9251; ysigf = 0.15;

[hbs,xdata,mVar,semVar,combs,p,h] = ...
    view_results_rmanova(ff.h_axes(1,1),ra,...
    {'St','hsd',0.05},[1 2],tcolors,...
    [mY MY ysp ystf ysigf],mData);

format_axes(gca);

set(gca,'xcolor','k','ycolor','k',...
    'XTick',xdata,...
    'XTickLabel',{'Air-Off','Air-On'});

xtickangle(30);
ylabel({'Avg. Motion Energy (A.U.)'});

x_on  = energy_off_all(:);
x_off = energy_on_all(:);

hold on

jitter = 0.05;  % small horizontal spread
rng(1);         % reproducible

for i = 1:length(x_on)

    % jittered x positions
    x1 = xdata(1) + jitter;
    x2 = xdata(2) - jitter;

    % connecting line
    plot([x1 x2], [x_on(i) x_off(i)], '-', ...
        'Color', [0.6 0.6 0.6], 'LineWidth', 0.75);

    % dots
    plot(x1, x_on(i), '.', ...
        'MarkerFaceColor', 'w', ...
        'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5);

    plot(x2, x_off(i), '.', ...
        'MarkerFaceColor', 'w', ...
        'MarkerEdgeColor', 'k', ...
        'MarkerSize', 5);
end

% ylim([0 5])

save_pdf(ff.hf,mData.pdf_folder,'bar_graphs_energy_animals.pdf',600);



%% rest vs motion FR average

air_on_idx  = onsets;   % air onset indices
air_off_idx = offsets;   % air offset indices

nTrials = numel(air_on_idx);

meanSpeed_ON  = nan(nTrials,1);
meanSpeed_OFF = nan(nTrials,1);

for k = 1:nTrials
    % Air ON window
    idx_on = air_on_idx(k):air_off_idx(k);
    meanSpeed_ON(k) = mean(speed(idx_on), 'omitnan');

    % Preceding Air OFF window
    if k == 1
        idx_off = 1:(air_on_idx(k)-1);
    else
        idx_off = air_off_idx(k-1):(air_on_idx(k)-1);
    end

    meanSpeed_OFF(k) = mean(speed(idx_off), 'omitnan');
end



    
tcolors = {'b','c'};
    data_C = [meanSpeed_ON meanSpeed_OFF];
    [within,dvn,xlabels] = make_within_table({'St'},[2]);
    dataT = make_between_table({data_C},dvn);
    ra = RMA(dataT,within,{0.05,{'hsd'}});
%     ra.ranova
print_for_manuscript(ra)
   magfac = mData.magfac;
% visualization
mData = evalin('base','mData'); colors = mData.colors; sigColor = mData.sigColor; axes_font_size = mData.axes_font_size; dcolors = mData.dcolors;
tcolors = repmat(mData.dcolors(1:3),1,2);

tcolors = {'b','c'};
% figure(300);clf; ha = gca;
ff = makeFigureRowsCols(2020,[10 4 1.25 1.5],'RowsCols',[1 1],'spaceRowsCols',[0.07 0],'rightUpShifts',[0.25 0.2],'widthHeightAdjustment',[-550 -280]);
MY = 0.35; ysp = 0.0925; mY = 0; ystf = 0.09251; ysigf = 0.015;titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80
[hbs,xdata,mVar,semVar,combs,p,h] = view_results_rmanova(ff.h_axes(1,1),ra,{'St','hsd',0.05},[1 2],tcolors,[mY MY ysp ystf ysigf],mData);
% make_bars_hollow(hbs(2))
format_axes(gca);
set(gca,'xcolor','k','ycolor','k','xlim',xlim,'ylim',ylim,...
    'XTick',xdata,'XTickLabel',{'Air-On','Air-Off'});xtickangle(30);
ylabel({'Avg. OF Avg. Speed'});
% set_bar_graph_sub_xtick_text(ff.hf,gca,hbs,2,{'Pooled'},{[0 0]});
% ht = set_axes_top_text_no_line(ff.hf,gca,sprintf('C1 - AOn'),[0.051 0.0 0 0]); 
save_pdf(ff.hf,mData.pdf_folder,sprintf('bar_graphs.pdf'),600);
%% rest vs motion FR average

air_on_idx  = onsets;   % air onset indices
air_off_idx = offsets;   % air offset indices

nTrials = numel(air_on_idx);

meanSpeed_ON  = nan(nTrials,1);
meanSpeed_OFF = nan(nTrials,1);

for k = 1:nTrials
    % Air ON window
    idx_on = air_on_idx(k):air_off_idx(k);
    meanSpeed_ON(k) = mean(motion_energy(idx_on), 'omitnan');

    % Preceding Air OFF window
    if k == 1
        idx_off = 1:(air_on_idx(k)-1);
    else
        idx_off = air_off_idx(k-1):(air_on_idx(k)-1);
    end

    meanSpeed_OFF(k) = mean(motion_energy(idx_off), 'omitnan');
end



    
tcolors = {'b','c'};
    data_C = [meanSpeed_ON meanSpeed_OFF];
    [within,dvn,xlabels] = make_within_table({'St'},[2]);
    dataT = make_between_table({data_C},dvn);
    ra = RMA(dataT,within,{0.05,{'hsd'}});
%     ra.ranova
print_for_manuscript(ra)
   magfac = mData.magfac;
% visualization
mData = evalin('base','mData'); colors = mData.colors; sigColor = mData.sigColor; axes_font_size = mData.axes_font_size; dcolors = mData.dcolors;
tcolors = repmat(mData.dcolors(1:3),1,2);

tcolors = {'r','m'};
% figure(300);clf; ha = gca;
ff = makeFigureRowsCols(2020,[10 4 1.25 1.5],'RowsCols',[1 1],'spaceRowsCols',[0.07 0],'rightUpShifts',[0.25 0.2],'widthHeightAdjustment',[-550 -280]);
MY = 4.5; ysp = 0.925; mY = 0; ystf = 0.9251; ysigf = 0.15;titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80
[hbs,xdata,mVar,semVar,combs,p,h] = view_results_rmanova(ff.h_axes(1,1),ra,{'St','hsd',0.05},[1 2],tcolors,[mY MY ysp ystf ysigf],mData);
% make_bars_hollow(hbs(2))
format_axes(gca);
set(gca,'xcolor','k','ycolor','k','xlim',xlim,'ylim',ylim,...
    'XTick',xdata,'XTickLabel',{'Air-On','Air-Off'});xtickangle(30);
ylabel({'Avg. Energy'});
% set_bar_graph_sub_xtick_text(ff.hf,gca,hbs,2,{'Pooled'},{[0 0]});
% ht = set_axes_top_text_no_line(ff.hf,gca,sprintf('C1 - AOn'),[0.051 0.0 0 0]); 
save_pdf(ff.hf,mData.pdf_folder,sprintf('bar_graphs.pdf'),600);


%% ---------- 1. Parameter Setup ----------
win_pre  = 5;  % seconds
win_post = 5;  % seconds
fs       = 60; % Sampling rate (frames per second)
Npre     = round(win_pre  * fs);
Npost    = round(win_post * fs);

signal   = pupil_area_sync; % Your data vector

% Initialize arrays for mean values
pre_means  = []; 
post_means = [];

% ---------- 2. Extraction Loop ----------
for i = 1:length(onsets)
    idx = onsets(i);
    
    % Ensure the window is within the bounds of the signal
    if idx > Npre && idx + Npost <= length(signal)
        
        % Extract the pre-event segment (5s before onset)
        pre_segment = signal(idx - Npre : idx - 1);
        
        % Extract the post-event segment (5s starting at onset)
        post_segment = signal(idx : idx + Npost);
        
        % Calculate and store the mean for this specific trial
        pre_means(end+1)  = mean(pre_segment, 'omitnan');
        post_means(end+1) = mean(post_segment, 'omitnan');
        
    end
end

% Display results for verification
fprintf('Extracted means for %d valid trials.\n', length(pre_means));

