%%
magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 1.5 1], ...
    'RowsCols',[1 1], ...
    'spaceRowsCols',[0.02 -0.02], ...
    'rightUpShifts',[0.15 0.25], ...
    'widthHeightAdjustment',[10 -300]);

MY = 10; 
ysp = 0.15285; 
mY = -1;

stp = 0.22*magfac; 
widths = [0.75 1 2.85 1]*magfac; 
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
ylim([0 8])


format_axes(gca);

save_pdf(ff.hf,mD.pdf_folder,'air_onset_speed_ALL_ANIMALS.pdf',600);

%%
%%

%% PARAMETERS
win_pre  = 2;   % seconds
win_post = 5;   % seconds

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

magfac = mD.magfac;

ff = makeFigureRowsCols(107,[3 5 1.5 1], ...
    'RowsCols',[1 1], ...
    'spaceRowsCols',[0.02 -0.02], ...
    'rightUpShifts',[0.15 0.25], ...
    'widthHeightAdjustment',[10 -300]);

MY = 10;
mY = -1;

stp = 0.22*magfac;
widths = [0.75 1 2.85 1]*magfac;
gap = 0.115*magfac;

adjust_axes(ff,[mY MY],stp,widths,gap,{''});

hold on

% ⭐ population mean
shadedErrorBar(t_evt,grand_mean,grand_sem);
plot(t_evt, grand_mean, 'k', 'LineWidth', 2);

xlabel('Time from air offset (s)')
ylabel('Speed (cm/s)')
xlim([-2 win_post+0.5])
ylim([0 8])

box off
format_axes(gca);

save_pdf(ff.hf, mD.pdf_folder, 'air_offset_speed_ALL_ANIMALS.pdf', 600);
