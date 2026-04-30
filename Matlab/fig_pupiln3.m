function fig_pupil()


% vp = evalin('base','vp');
% vf = evalin('base','vf');
% v = evalin('base','v');
mD = evalin('base','mData'); colors = mD.colors; sigColor = mD.sigColor; axes_font_size = mD.axes_font_size;
mData = mD;
animals = evalin('base','animals');

% animal = animals(4);
% disp(animal.ID)
n = 0;

%%
aniii = 0;
for anii = 1:length(animals)
    % aniii = aniii + 1;
    animal = animals(anii);
    disp(animal.ID)
T = animal(1).b.led_sig.("pupil");
t_paws = T.time/60;
air_pupil = double(T.is_on);
time_sync = animal(1).epsig.time_sync;
pupil_area_sync = animal(1).epsig.pupil_area_sync;
% Figure raw data
magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 4.5 1.5],'RowsCols',[1 1],'spaceRowsCols',[0.01 -0.02],'rightUpShifts',[0.08 0.24],...
    'widthHeightAdjustment',[-100 -350]);
time_syncM = time_sync/60;
% --- Subplot 1: Pupil Area in Physical Units ---
% subplot(2,1,1);
plot(time_syncM, pupil_area_sync, 'k', 'LineWidth', 0.25);
ylabel('Eye-Pupil Area (cm^2)');
% title('Eye-Pupil Dynamics: Dilation');
box off;
% format_axes(gca); % Uncomment if you have your custom formatting function

% % --- Subplot 2: Pupil Center Position (Gaze/Drift) ---
% subplot(2,1,2);
% % Plot X and Y positions. Subtracting the mean helps visualize "drift" 
% % rather than absolute pixel coordinates.
% plot(time_sync, pupil_center_sync(:,1), 'Color', [0 0.447 0.741], 'LineWidth', 1); hold on;
% plot(time_sync, pupil_center_sync(:,2), 'Color', [0.85 0.32 0.1], 'LineWidth', 1);
% 
% ylabel('Global Position (px)');
xlabel('Time (s)');
xlim([0 time_syncM(end)]);
% xlim([0 3])
% legend({'X-Pos', 'Y-Pos'}, 'Location', 'best', 'Box', 'off');
% title('Eye-Pupil Center: Spatial Tracking');
box off;
format_axes(gca)
onsets = find_rising_edge(air_pupil,0.5,-1);
offsets = find_falling_edge(air_pupil,-0.5,1);

[onsets, offsets] = sanitize_air_sig(onsets,offsets);


ylims = ylim;
[TLx TLy] = ds2nfu(time_syncM(onsets(1)),ylims(2)-0);
axes(ff.h_axes(1,1));ylims = ylim;
[BLx BLy] = ds2nfu(time_syncM(onsets(1)),ylims(1));
aH = (TLy - BLy);
len = sum(find(time_syncM(onsets)<3,1,'last'));
for ii = 1:length(onsets)
    [BRx BRy] = ds2nfu(time_syncM(offsets(ii)),ylims(1));
    [BLx BLy] = ds2nfu(time_syncM(onsets(ii)),ylims(1));
    aW = (BRx-BLx);
    annotation('rectangle',[BLx BLy aW aH],'facealpha',0.2,'linestyle','none','facecolor','k');
end
% format_axes(gca); % Uncomment if you have your custom formatting function

% Save results to your PDF folder
save_pdf(gcf, mD.pdf_folder, 'Pupil_Dynamics_Final_Plot.pdf', 600);


% rest vs motion FR average

air_on_idx  = onsets;   % air onset indices
air_off_idx = offsets;   % air offset indices

[air_on_idx, air_off_idx] = sanitize_air_sig(air_on_idx,air_off_idx);

nTrials = numel(air_on_idx);

meanSpeed_ON  = nan(nTrials,1);
meanSpeed_OFF = nan(nTrials,1);

for k = 1:nTrials
    % Air ON window
    idx_on = air_on_idx(k):air_off_idx(k);
    meanSpeed_ON(k) = mean(pupil_area_sync(idx_on), 'omitnan');

    % Preceding Air OFF window
    if k == 1
        idx_off = 1:(air_on_idx(k)-1);
    else
        idx_off = air_off_idx(k-1):(air_on_idx(k)-1);
    end

    meanSpeed_OFF(k) = mean(pupil_area_sync(idx_off), 'omitnan');
end
all_meanSpeed_ON(anii) = mean(meanSpeed_ON);
all_meanSpeed_OFF(anii) = mean(meanSpeed_OFF);
end
%%
    
tcolors = {'b','c'};
    data_C = [all_meanSpeed_OFF' all_meanSpeed_ON'];
    [within,dvn,xlabels] = make_within_table({'St'},[2]);
    dataT = make_between_table({data_C},dvn);
    ra = RMA(dataT,within,{0.05,{'hsd'}});
%     ra.ranova
print_for_manuscript(ra)
formatMeanSEM(ra.EM.St)
   magfac = mData.magfac;
% visualization
mData = evalin('base','mData'); colors = mData.colors; sigColor = mData.sigColor; axes_font_size = mData.axes_font_size; dcolors = mData.dcolors;
tcolors = repmat(mData.dcolors(1:3),1,2);

tcolors = {'k',[0.5 0.5 0.5]};
% figure(300);clf; ha = gca;
ff = makeFigureRowsCols(2020,[10 4 1.25 1.5],'RowsCols',[1 1],'spaceRowsCols',[0.07 0],'rightUpShifts',[0.27 0.2],'widthHeightAdjustment',[-550 -280]);
MY = 0.0375; ysp = 0.007125; mY = 0; ystf = 0.0051; ysigf = 0.0015;titletxt = ''; ylabeltxt = {'PDF'}; % for all cells (vals) MY = 80
[hbs,xdata,mVar,semVar,combs,p,h] = view_results_rmanova(ff.h_axes(1,1),ra,{'St','hsd',0.05},[1 2],tcolors,[mY MY ysp ystf ysigf],mData);
% make_bars_hollow(hbs(2))
format_axes(gca);
set(gca,'xcolor','k','ycolor','k','xlim',xlim,'ylim',ylim,...
    'XTick',xdata,'XTickLabel',{'Air-On','Air-Off'});xtickangle(30);
ylabel({'Avg. Eye-Pupil Area (cm^2)'});
% set_bar_graph_sub_xtick_text(ff.hf,gca,hbs,2,{'Pooled'},{[0 0]});
% ht = set_axes_top_text_no_line(ff.hf,gca,sprintf('C1 - AOn'),[0.051 0.0 0 0]); 

x_on  = all_meanSpeed_OFF(:);
x_off = all_meanSpeed_ON(:);

hold on

jitter = 0.05;  % small horizontal spread
rng(1);         % reproducible

for i = 1:length(x_on)

    % jittered x positions
    x1 = xdata(1) + jitter;
    x2 = xdata(2) - jitter;

    % connecting line
    plot([x1 x2], [x_on(i) x_off(i)], '-', ...
        'Color', [0.7 0.7 0.7], 'LineWidth', 0.75);

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


save_pdf(ff.hf,mData.pdf_folder,sprintf('bar_graphs.pdf'),600);
