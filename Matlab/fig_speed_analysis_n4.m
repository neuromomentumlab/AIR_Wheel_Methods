function fig_speed_analysis

% vp = evalin('base','vp');
% vf = evalin('base','vf');
% v = evalin('base','v');
mD = evalin('base','mData'); colors = mD.colors; sigColor = mD.sigColor; axes_font_size = mD.axes_font_size;
mData = mD;
animals = evalin('base','animals');
animal = animals;
n = 0;

%%
results = analyze_air_training(animal,24.5,3.5);
for a = 1:numel(results)
    fprintf('Animal %d: %d/%d good trials (%.2f%%)\n', ...
        a, results(a).n_good_trials, results(a).n_trials, results(a).success_rate);
end

window = 5;
figure(100);clf; hold on
for a = 1:numel(results)
    gt = double(results(a).good_trial);
    smooth_perf = movmean(gt, window);

    
    plot(gt, 'o-');
    plot(smooth_perf, 'LineWidth', 2);
    
    xlabel('Trial');
    ylabel('Success');
    title(['Animal ' num2str(a)]);
    ylim([-0.1 1.1]);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%
%% after 2nd review
%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%

%% Parameters

nAnimals = numel(animal);

meanSpeed_ON_animal  = nan(nAnimals,1);
meanSpeed_OFF_animal = nan(nAnimals,1);

medSpeed_ON_animal  = nan(nAnimals,1);
medSpeed_OFF_animal = nan(nAnimals,1);

% Loop over animals
for a = 1:nAnimals
    
    b = animal(a).b;
   
    % 
    % --- recompute distance & speed (safe) ---
    % b.dist = b.encoderCount * pi * 32 / b.countsPerRev; % cm
    % b.speed = diff(b.dist)./diff(b.t); % cm/sec
    % b.speed = double([0; b.speed]);
    % removeOutliersFlag = true;   % <-- toggle here if needed
    % if removeOutliersFlag
    % 
    %     % --- robust outlier detection ---
    %     % Uses median absolute deviation (very stable)
    %     outlier_idx = isoutlier(b.fSpeed,'median');
    % 
    %     % Optional: also catch absurd physical speeds
    %     maxPhysSpeed = 200; % cm/s (adjust if needed)
    %     outlier_idx = outlier_idx | abs(b.fSpeed) > maxPhysSpeed;
    % 
    %     % --- replace with interpolation (keeps length same) ---
    %     b.fSpeed(outlier_idx) = NaN;
    %     b.fSpeed = fillmissing(b.fSpeed,'linear','EndValues','nearest');
    % 
    % end
    % % --- smooth speed (same as your code) ---
    % samplingRate = b.fs;
    % coeffs = ones(1, samplingRate)/samplingRate;
    % b.fSpeed = filter(coeffs, 1, b.speed);

    % --- air indices ---
    air_on_idx  = b.Air_r(:);
    air_off_idx = b.Air_f(:);


    % =========================================
    % FIX AIR ON/OFF ORDERING (robust)
    % =========================================
    
    % Remove any OFF that occurs before first ON
    air_off_idx(air_off_idx < air_on_idx(1)) = [];
    
    % Remove any ON that occurs after last OFF
    air_on_idx(air_on_idx > air_off_idx(end)) = [];
    
    % Make lengths equal
    nPairs = min(numel(air_on_idx), numel(air_off_idx));
    air_on_idx  = air_on_idx(1:nPairs);
    air_off_idx = air_off_idx(1:nPairs);
    
    % Safety: enforce ON < OFF for every trial
    badPairs = air_off_idx <= air_on_idx;
    
    if any(badPairs)
        warning('Fixing misordered air events...')
        air_on_idx(badPairs)  = [];
        air_off_idx(badPairs) = [];
    end

    all_dists{a} = [b.dist(air_off_idx)-b.dist(air_on_idx)]';
    all_times{a} = [b.t(air_off_idx)-b.t(air_on_idx)]';
    
    nTrials = numel(air_on_idx);
    if nAnimals == 1
        start_trial = 1;
    else
        start_trial = 5;
    end
    meanSpeed_ON  = nan(length(start_trial:(nTrials)),1);
    meanSpeed_OFF = nan(length(start_trial:(nTrials)),1);
    num_trial_animals(a) = nTrials;
    k = 0;
   % Trial loop
    for ki = start_trial:(nTrials)
        k = k + 1;
        % ---------- AIR ON phase ----------
        idx_on = air_on_idx(k):air_off_idx(k);
        idx_on(idx_on < 1 | idx_on > numel(b.fSpeed)) = [];

        meanSpeed_ON(k) = mean(b.fSpeed(idx_on),'omitnan');
        medSpeed_ON(k) = median(b.fSpeed(idx_on),'omitnan');

        % ---------- AIR OFF phase ----------
        if k == 1
            idx_off = 1:(air_on_idx(k)-1);
        else
            idx_off = air_off_idx(k-1):(air_on_idx(k)-1);
        end

        idx_off(idx_off < 1 | idx_off > numel(b.fSpeed)) = [];

        meanSpeed_OFF(k) = mean(b.fSpeed(idx_off),'omitnan');
        medSpeed_OFF(k) = median(b.fSpeed(idx_off),'omitnan');
    end

    % Animal-level means
    meanSpeed_ON_animal(a)  = mean(meanSpeed_ON,'omitnan');
    meanSpeed_OFF_animal(a) = mean(meanSpeed_OFF,'omitnan');
    medSpeed_ON_animal(a)  = median(medSpeed_ON,'omitnan');
    medSpeed_OFF_animal(a) = median(medSpeed_OFF,'omitnan');

end
[meanSpeed_ON_animal medSpeed_ON_animal meanSpeed_OFF_animal medSpeed_OFF_animal]
[p, h, stats] = signrank(medSpeed_ON_animal, medSpeed_OFF_animal);
%%
tcolors = {'b','m'};
    data_C = [meanSpeed_OFF_animal meanSpeed_ON_animal];
    % data_C = [meanSpeed_OFFmeanSpeed_ON ];
    [within,dvn,xlabels] = make_within_table({'St'},[2]);
    dataT = make_between_table({data_C},dvn);
    ra = RMA(dataT,within,{0.05,{'hsd'}});
%     ra.ranova
print_for_manuscript(ra)
formatMeanSEM(ra.EM.St)
    % data_C = [medSpeed_ON_animal medSpeed_OFF_animal];
    % [p,h] = signrank(medSpeed_ON_animal, medSpeed_OFF_animal);
    % x_on  = medSpeed_ON_animal(:);
    % x_off = medSpeed_OFF_animal(:);
    % [p,h] = signrank(x_on, x_off);
    % meds = [median(x_on) median(x_off)];
    % 
    % q_on  = prctile(x_on,[25 75]);
    % q_off = prctile(x_off,[25 75]);
    % 
    % err_low  = [meds(1)-q_on(1), meds(2)-q_off(1)];
    % err_high = [q_on(2)-meds(1), q_off(2)-meds(2)];
    % 
    % semVar = [err_low; err_high]; % for asymmetric errorbars
    % mVar   = meds;

   magfac = mData.magfac;
% visualization
mData = evalin('base','mData'); colors = mData.colors; sigColor = mData.sigColor; axes_font_size = mData.axes_font_size; dcolors = mData.dcolors;
tcolors = repmat(mData.dcolors(1:3),1,2);

tcolors = {'m','b'};
% figure(300);clf; ha = gca;
ff = makeFigureRowsCols(2020,[10 4 1.25 1.5],'RowsCols',[1 1],'spaceRowsCols',[0.07 0],'rightUpShifts',[0.2 0.2],'widthHeightAdjustment',[-550 -280]);
MY = 8; ysp = 0.75; mY = 0; ystf = 1.75; ysigf = 0.5;titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80
% MY = 10; ysp = 0.75; mY = 0; ystf = 1.75; ysigf = 0.5;titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80

% [xdata,mVar,semVar,combs,p,h] = get_vals_RMA(mData,ra,{'St','hsd'},[1 2],'no');

% [hbs,maxY] = plotBarsWithSigLines(mVar,semVar,[1 2],[h p],'colors',tcolors,'sigColor','k',...
% 'ySpacing',ysp,'sigTestName','','sigLineWidth',0.25,'BaseValue',0.01,'capsize',1,...
% 'xdata',xdata,'sigFontSize',7,'sigAsteriskFontSize',mData.asterisk_font_size,'barWidth',0.5,'sigLinesStartYFactor',ystf,'sigAsteriskyshift',ysigf);

 [hbs,xdata,mVar,semVar,combs,p,h] = view_results_rmanova(ff.h_axes(1,1),ra,{'St','hsd',0.05},[1 2],tcolors,[mY MY ysp ystf ysigf],mData);
% make_bars_hollow(hbs(2))
format_axes(gca);
set(gca,'xcolor','k','ycolor','k','xlim',xlim,'ylim',ylim,...
    'XTick',xdata,'XTickLabel',{'Air-Off','Air-On'});xtickangle(30);
ylabel({'Avg. Speed (cm/s)'});
set_axes_limits(gca,[xdata(1)-0.75 xdata(end)+0.75],[mY MY]); 

% ================================
% Add paired animal dots
% ================================

x_on  = meanSpeed_OFF_animal(:);
x_off = meanSpeed_ON_animal(:);

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


% x_on  = medSpeed_ON_animal(:);
% x_off = medSpeed_OFF_animal(:);
% 
% hold on
% 
% jitter = -0.4;  % small horizontal spread
% rng(1);         % reproducible
% 
% for i = 1:length(x_on)
% 
%     % jittered x positions
%     x1 = xdata(1) + jitter;
%     x2 = xdata(2) + jitter;
% 
%     % connecting line
%     plot([x1 x2], [x_on(i) x_off(i)], '-', ...
%         'Color', [0.6 0.6 0.6], 'LineWidth', 0.75);
% 
%     % dots
%     plot(x1, x_on(i), 'o', ...
%         'MarkerFaceColor', 'w', ...
%         'MarkerEdgeColor', 'k', ...
%         'MarkerSize', 5);
% 
%     plot(x2, x_off(i), 'o', ...
%         'MarkerFaceColor', 'w', ...
%         'MarkerEdgeColor', 'k', ...
%         'MarkerSize', 5);
% end
% 

hold off
format_axes(gca);

% set_bar_graph_sub_xtick_text(ff.hf,gca,hbs,2,{'Pooled'},{[0 0]});
% ht = set_axes_top_text_no_line(ff.hf,gca,sprintf('C1 - AOn'),[0.051 0.0 0 0]); 
save_pdf(ff.hf,mData.pdf_folder,sprintf('bar_graphs.pdf'),600);

%%
%% PARAMETERS
win_pre  = 2;   % seconds
win_post = 5;   % seconds

nAnimals = numel(animal);
animal_traces = [];

for a = 1:nAnimals

    b = animal(a).b;

    removeOutliersFlag = false;   % <-- toggle here if needed
    if removeOutliersFlag

        % --- robust outlier detection ---
        % Uses median absolute deviation (very stable)
        outlier_idx = isoutlier(b.fSpeed,'median');

        % Optional: also catch absurd physical speeds
        maxPhysSpeed = 100; % cm/s (adjust if needed)
        outlier_idx = outlier_idx | abs(b.fSpeed) > maxPhysSpeed;

        % --- replace with interpolation (keeps length same) ---
        b.fSpeed(outlier_idx) = NaN;
        b.fSpeed = fillmissing(b.fSpeed,'linear','EndValues','nearest');

    end

    Npre  = round(win_pre  * b.fs);
    Npost = round(win_post * b.fs);

    trials = [];

    for i = 5:length(b.Air_r)
        idx = b.Air_r(i);

        if idx > Npre && idx + Npost <= length(b.fSpeed)
            trials(:,end+1) = b.fSpeed(idx-Npre : idx+Npost);
        end
    end

    %  average within animal FIRST
    animal_mean_trace(:,a) = mean(trials,2,'omitnan');

end

t_evt = linspace(-win_pre, win_post, size(animal_mean_trace,1));

grand_mean = mean(animal_mean_trace,2,'omitnan');
grand_sem  = std(animal_mean_trace,[],2,'omitnan') ./ sqrt(nAnimals);


%%
magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 1.75 1.5], ...
    'RowsCols',[1 1], ...
    'spaceRowsCols',[0.02 -0.02], ...
    'rightUpShifts',[0.15 0.22], ...
    'widthHeightAdjustment',[10 -250]);

MY = 10; 
ysp = 0.15285; 
mY = -1;

stp = 0.25*magfac; 
widths = [1.5 1 2.85 1]*magfac; 
gap = 0.115*magfac;

adjust_axes(ff,[mY MY],stp,widths,gap,{''});

hold on

% % shaded SEM band (better than dashed)
% fill([t_evt fliplr(t_evt)], ...
%      [grand_mean'+grand_sem' fliplr(grand_mean'-grand_sem')], ...
%      [0.7 0.7 0.7], ...
%      'EdgeColor','none', ...
%      'FaceAlpha',0.4);
% 
% % mean line
shadedErrorBar(t_evt,grand_mean,grand_sem);
plot(t_evt, grand_mean, 'k', 'LineWidth', 2);

xlabel('Time from air onset (s)')
ylabel('Speed (cm/s)')
xlim([-2 5.5]);
ylim([0 10])

box off
format_axes(gca);

save_pdf(ff.hf,mD.pdf_folder,'air_onset_speed_ALL_ANIMALS.pdf',600);

%%

%% PARAMETERS
win_pre  = 2;   % seconds
win_post = 6;   % seconds

nAnimals = numel(animal);
animal_mean_trace = [];

for a = 1:nAnimals

    b = animal(a).b;
    
    removeOutliersFlag = false;   % <-- toggle here if needed
    if removeOutliersFlag

        % --- robust outlier detection ---
        % Uses median absolute deviation (very stable)
        outlier_idx = isoutlier(b.fSpeed,'median');

        % Optional: also catch absurd physical speeds
        maxPhysSpeed = 100; % cm/s (adjust if needed)
        outlier_idx = outlier_idx | abs(b.fSpeed) > maxPhysSpeed;

        % --- replace with interpolation (keeps length same) ---
        b.fSpeed(outlier_idx) = NaN;
        b.fSpeed = fillmissing(b.fSpeed,'linear','EndValues','nearest');

    end


    Npre  = round(win_pre  * b.fs);
    Npost = round(win_post * b.fs);

    trials = [];

    for i = 5:length(b.Air_f)

        idx = b.Air_f(i);

        if idx > Npre && idx + Npost <= length(b.fSpeed)
            trials(:,end+1) = b.fSpeed(idx-Npre : idx+Npost);
        end
    end

    % average within animal FIRST
    animal_mean_trace(:,a) = mean(trials,2,'omitnan');

end

t_evt = linspace(-win_pre, win_post, size(animal_mean_trace,1));
grand_mean = mean(animal_mean_trace,2,'omitnan');
grand_sem  = std(animal_mean_trace,[],2,'omitnan') ./ sqrt(nAnimals);
%%
magfac = mD.magfac;

ff = makeFigureRowsCols(107,[3 5 1.75 1.5], ...
    'RowsCols',[1 1], ...
    'spaceRowsCols',[0.02 -0.02], ...
    'rightUpShifts',[0.15 0.22], ...
    'widthHeightAdjustment',[10 -250]);

MY = 10;
mY = -1;

stp = 0.25*magfac;
widths = [1.5 1 2.85 1]*magfac;
gap = 0.115*magfac;

adjust_axes(ff,[mY MY],stp,widths,gap,{''});

hold on

% ⭐ population mean
shadedErrorBar(t_evt,grand_mean,grand_sem);
plot(t_evt, grand_mean, 'k', 'LineWidth', 2);

xlabel('Time from air offset (s)')
ylabel('Speed (cm/s)')
xlim([-2 win_post+0.5])
ylim([0 10])

box off
format_axes(gca);

save_pdf(ff.hf, mD.pdf_folder, 'air_offset_speed_ALL_ANIMALS.pdf', 600);

%%
%% =========================================
% MULTI-ANIMAL COLLECTION
% =========================================

nAnimals = numel(animal);

mean_speed_on_anim  = nan(nAnimals,1);
mean_speed_off_anim = nan(nAnimals,1);

all_on_speeds  = [];
all_off_speeds = [];

for a = 1:nAnimals

    b = animal(a).b;

    removeOutliersFlag = false;   % <-- toggle here if needed
    if removeOutliersFlag

        % --- robust outlier detection ---
        % Uses median absolute deviation (very stable)
        outlier_idx = isoutlier(b.fSpeed,'median');

        % Optional: also catch absurd physical speeds
        maxPhysSpeed = 100; % cm/s (adjust if needed)
        outlier_idx = outlier_idx | abs(b.fSpeed) > maxPhysSpeed;

        % --- replace with interpolation (keeps length same) ---
        b.fSpeed(outlier_idx) = NaN;
        b.fSpeed = fillmissing(b.fSpeed,'linear','EndValues','nearest');

    end

    speed   = b.fSpeed(:);
    air_bin = b.air_bin(:);

    speed(1:(b.Air_r(5)-5000)) = [];
    air_bin(1:(b.Air_r(5)-5000)) = [];

    idx_on  = air_bin == 1;
    idx_off = air_bin == 0;
    minvals_on(a) = min(speed(idx_on));
    minvals_off(a) = min(speed(idx_off));
    maxvals_on(a) = max(speed(idx_on));
    maxvals_off(a) = max(speed(idx_off));

    % ---------- per-animal means (IMPORTANT) ----------
    mean_speed_on_anim(a)  = mean(speed(idx_on),'omitnan');
    mean_speed_off_anim(a) = mean(speed(idx_off),'omitnan');

    % ---------- pooled distributions (OK for KS) ----------
    all_on_speeds  = [all_on_speeds;  speed(idx_on)];
    all_off_speeds = [all_off_speeds; speed(idx_off)];

    speed_animal_on{a} = speed(idx_on);
    speed_animal_off{a} = speed(idx_off);

end

%% plot distributions Air On vs Air Off
magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 1.75 1.5],'RowsCols',[1 1],'spaceRowsCols',[0.02 -0.02],'rightUpShifts',[0.15 0.22],...
    'widthHeightAdjustment',[10 -250]);
MY = 2; ysp = 0.15285; mY = -2.5; titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80
stp = 0.3*magfac; widths = [1.35 1 2.85 1]*magfac; gap = 0.115*magfac;
adjust_axes(ff,[mY MY],stp,widths,gap,{''});
axes_title_shifts_line = [0 0.55 0 0]; axes_title_shifts_text = [0.02 0.1 0 0]; xs_gaps = [1 2];
hold on;
distD = {speed(idx_on),speed(idx_off)};
distD = [speed_animal_on',speed_animal_off'];

tcolors = {'b','m'};
[distDo,allVals,allValsG] = plotDistributions(distD);
minBin = min(allVals);
maxBin = max(allVals);
incr = 1;
% [ha,hb,hca] = plotDistributions(allValsG,'colors',tcolors,'maxY',100,'min',minBin,'incr',incr,'max',maxBin,'do_mean','No');
[ha,hb,hca] = plotDistributions(distDo,'colors',tcolors,'maxY',100,'min',minBin,'incr',incr,'max',maxBin,'do_mean','Yes');
set(gca,'FontSize',6,'FontWeight','Bold','TickDir','out','xcolor','k','ycolor','k');
%     changePosition(gca,[0.129 0.15 -0.09 -0.13]);
ylim([0 100]); xlim([minBin maxBin]); %xlim([minBin 0.5]);
put_axes_labels(ha,{{'Speed (cm/s)'},[0 0 0]},{{'%'},[0 0 0]});
format_axes(ha);
[ks.h,ks.p,ks.ks2stat] = kstest2(allValsG{1},allValsG{2});
ks.DF1 = length(allValsG{1}); ks.DF2 = length(allValsG{2});
ht = set_axes_top_text_no_line(gcf,ha,'KS-Test',[0.0351 -0.01 0.1 0]);set(ht,'FontSize',7);
titletxt = sprintf('%s',getNumberOfAsterisks(ks.p));
ht = set_axes_top_text_no_line(gcf,ha,titletxt,[0.1 -0.1 0.1 0]);set(ht,'FontSize',9);
% legend('Air-On','Air-Off','Location','SouthEast')
% titletxt = sprintf('n = %d,',length(allValsG{1}));
% ht = set_axes_top_text_no_line(gcf,ha,titletxt,[0.015 -0.45 0 0]);set(ht,'FontSize',7,'Color','k');
% titletxt = sprintf('%d',length(allValsG{2}));
% ht = set_axes_top_text_no_line(gcf,ha,titletxt,[0.067 -0.45 0 0]);set(ht,'FontSize',7,'Color','r');
save_pdf(ff.hf,mData.pdf_folder,'firing_rate.pdf',600);


function results = analyze_air_training(animal, criterionDistance, speedThreshold)

nAnimals = numel(animal);
results = struct();

for a = 1:nAnimals

    b = animal(a).b;

    air_on_idx  = b.Air_r(:);
    air_off_idx = b.Air_f(:);

    % Fix ordering
    air_off_idx(air_off_idx < air_on_idx(1)) = [];
    air_on_idx(air_on_idx > air_off_idx(end)) = [];

    nPairs = min(numel(air_on_idx), numel(air_off_idx));
    air_on_idx  = air_on_idx(1:nPairs);
    air_off_idx = air_off_idx(1:nPairs);

    badPairs = air_off_idx <= air_on_idx;
    air_on_idx(badPairs)  = [];
    air_off_idx(badPairs) = [];

    nTrials = numel(air_on_idx);

    distance_on     = nan(nTrials,1);
    time_on         = nan(nTrials,1);
    mean_speed_on   = nan(nTrials,1);
    median_speed_on = nan(nTrials,1);
    max_speed_on    = nan(nTrials,1);

    distance_off    = nan(nTrials,1);
    time_off        = nan(nTrials,1);
    mean_speed_off  = nan(nTrials,1);

    good_trial      = false(nTrials,1);

    for ki = 1:nTrials

        % ---------------- AIR ON ----------------
        idx_on = air_on_idx(ki):air_off_idx(ki);
        idx_on = idx_on(idx_on >= 1 & idx_on <= numel(b.fSpeed));

        distance_on(ki)     = b.dist(air_off_idx(ki)) - b.dist(air_on_idx(ki));
        time_on(ki)         = b.t(air_off_idx(ki))    - b.t(air_on_idx(ki));
        mean_speed_on(ki)   = mean(b.fSpeed(idx_on), 'omitnan');
        median_speed_on(ki) = median(b.fSpeed(idx_on), 'omitnan');
        max_speed_on(ki)    = max(b.fSpeed(idx_on));

        % ---------------- AIR OFF ----------------
        if ki == 1
            idx_off = 1:(air_on_idx(ki)-1);
            distance_off(ki) = b.dist(air_on_idx(ki)) - b.dist(1);
            time_off(ki)     = b.t(air_on_idx(ki))    - b.t(1);
        else
            idx_off = air_off_idx(ki-1):air_on_idx(ki)-1;
            distance_off(ki) = b.dist(air_on_idx(ki)) - b.dist(air_off_idx(ki-1));
            time_off(ki)     = b.t(air_on_idx(ki))    - b.t(air_off_idx(ki-1));
        end

        idx_off = idx_off(idx_off >= 1 & idx_off <= numel(b.fSpeed));
        mean_speed_off(ki) = mean(b.fSpeed(idx_off), 'omitnan');

        % ---------------- GOOD TRIAL ----------------
        good_trial(ki) = (distance_on(ki) >= criterionDistance) && ...
                         (mean_speed_on(ki) >= speedThreshold);
    end

    % Store trial-wise results
    results(a).distance_on     = distance_on;
    results(a).time_on         = time_on;
    results(a).mean_speed_on   = mean_speed_on;
    results(a).median_speed_on = median_speed_on;
    results(a).max_speed_on    = max_speed_on;

    results(a).distance_off    = distance_off;
    results(a).time_off        = time_off;
    results(a).mean_speed_off  = mean_speed_off;

    results(a).good_trial      = good_trial;
    results(a).success_rate    = mean(good_trial) * 100;
    results(a).n_good_trials   = sum(good_trial);
    results(a).n_trials        = nTrials;
end