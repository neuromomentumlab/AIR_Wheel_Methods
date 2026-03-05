function fig_dlc

% vp = evalin('base','vp');
% 
% vp_l = evalin('base','vp_labeled');
% vf = evalin('base','vf');
% v = evalin('base','v');
mD = evalin('base','mData'); colors = mD.colors; sigColor = mD.sigColor; axes_font_size = mD.axes_font_size;
mData = mD;
animal = evalin('base','animal');

% physical_dist_cm = 5.0;  
% pixel_dist_px = 200; % Measure this from a still frame using 'imdistline'
px_to_cm = 0.0114; 

n = 0;
%%
num_animals = length(animal);

air_on_all  = nan(num_animals,6);
air_off_all = nan(num_animals,6);


for a = 1:num_animals

    entry = animal(a);
    pdir  = entry.pdir;

    % -------------------------
    % Load DLC CSV
    % -------------------------
    % file_path = fullfile(pdir,...
    % 'video_20251216_165824DLC_resnet50_gcamp16declimbDec18shuffle1_185000_filtered.csv');
    file_path = animal(a).video.mp4_labeled.paws;

    opts = detectImportOptions(file_path);
    opts.DataLines = [4 Inf];
    opts.VariableNamingRule = 'preserve';
    tbl = readtable(file_path,opts);


    % Define indices for X and Y based on your CSV structure
    % x: Col 2, 5, 8, 11, 14, 17 | y: Col 3, 6, 9, 12, 15, 18
    x_idx = [2, 5, 8, 11, 14, 17];
    y_idx = [3, 6, 9, 12, 15, 18];
    likelihood_idx = [4, 7, 10, 13, 16, 19];
    bodyparts = {'Front Right', 'Front Left', 'Hind Right', 'Hind Left', 'Tail Base', 'Nose'};

    fs = 60;

    % -------------------------
    % Extract coordinates
    % -------------------------
    X_coords = table2array(tbl(:,x_idx));
    Y_coords = table2array(tbl(:,y_idx));
    L        = table2array(tbl(:,likelihood_idx));

    % -------------------------
    % Likelihood filtering
    % -------------------------
    lik_thresh = 0.9;

    low_conf = L < lik_thresh;

    X_coords(low_conf) = NaN;
    Y_coords(low_conf) = NaN;

    X_coords = fillmissing(X_coords,'linear');
    Y_coords = fillmissing(Y_coords,'linear');

    % -------------------------
    % Smooth coordinates
    % -------------------------
    X_coords = movmedian(X_coords,5);
    Y_coords = movmedian(Y_coords,5);

    % -------------------------
    % Convert to cm
    % -------------------------
    X_cm = X_coords * px_to_cm;
    Y_cm = Y_coords * px_to_cm;

    % -------------------------
    % Velocity
    % -------------------------
    dx = [zeros(1,6); diff(X_cm)];
    dy = [zeros(1,6); diff(Y_cm)];

    speed = sqrt(dx.^2 + dy.^2) * fs;

    % -------------------------
    % Air signal
    % -------------------------
    T = entry.b.led_sig.paws;

    air = double(T.is_on);

    onsets  = find_rising_edge(air,0.5,-1);
    offsets = find_falling_edge(air,-0.5,1);

    nTrials = min(numel(onsets),numel(offsets));

    mean_on  = nan(nTrials,6);
    mean_off = nan(nTrials,6);

    for k = 1:nTrials

        idx_on = onsets(k):offsets(k);

        if k == 1
            idx_off = 1:onsets(k)-1;
        else
            idx_off = offsets(k-1):onsets(k)-1;
        end

        mean_on(k,:)  = mean(speed(idx_on,:),1,'omitnan');
        mean_off(k,:) = mean(speed(idx_off,:),1,'omitnan');

    end
    mean_on = mean_on(5:end,:);
    mean_off = mean_off(5:end,:);
    % -------------------------
    % Animal-level means
    % -------------------------
    air_on_all(a,:)  = mean(mean_on,1,'omitnan');
    air_off_all(a,:) = mean(mean_off,1,'omitnan');

    fprintf('Animal %d processed\n',a)

end

%% ---------- Updated Bodypart Colors (RGB) ----------
% These values are sampled directly from the markers in your images:
% Front Right (Blue/Indigo), Front Left (Sky Blue), Hind Right (Teal), 
% Hind Left (Bright Green), Tail Base (Orange), Nose (Red)
custom_colors = [
    0.20, 0.00, 1.00;  % Front Right (Dark Blue/Indigo)
    0.00, 0.60, 1.00;  % Front Left (Sky Blue)
    0.00, 0.80, 0.75;  % Hind Right (Teal)
    0.60, 1.00, 0.40;  % Hind Left (Bright Green)
    1.00, 0.60, 0.00;  % Tail Base (Orange)
    1.00, 0.00, 0.00   % Nose (Red)
];

%%
magfac = mD.magfac;
ff = makeFigureRowsCols(107,[3 5 6.75 1.5],'RowsCols',[1 6],'spaceRowsCols',[0.01 0.04],'rightUpShifts',[0.051 0.2],...
    'widthHeightAdjustment',[-45 -500]);
p_t = NaN(1,6);
nValid = size(air_off_all,1);
for i = 1:6
    % subplot(1,6,i);
    axes(ff.h_axes(1,i));% nexttile
    hold on
    mOn  = mean(air_on_all(:,i),  'omitnan');
    mOff = mean(air_off_all(:,i), 'omitnan');
    seOn  = std(air_on_all(:,i),  'omitnan')/sqrt(nValid);
    seOff = std(air_off_all(:,i), 'omitnan')/sqrt(nValid);
    
    data_all = [air_off_all(:,i) air_on_all(:,i)];

    [within,dvn,xlabels] = make_within_table({'State'},[2]);
    dataT = make_between_table({data_all},dvn);
    
    ra = RMA(dataT,within,{0.05,{'hsd'}});
    print_for_manuscript(ra)
    p_t(i) = ra.ps{1};

    hb = bar([1 2], [mOff mOn]); % OFF then ON
    errorbar([1 2], [mOff mOn], [seOff seOn], 'k.', 'LineWidth', 1);
    set(hb,'FaceColor',custom_colors(i,:))
    % paired dots
    for k = 1:nValid
        plot([1 2], [air_off_all(k,i) air_on_all(k,i)], '-', 'Color', [0 0 0 0.15]);
    end

    set(gca,'XTick',[1 2],'XTickLabel',{'Air-OFF','Air-ON'});xtickangle(30)
    if i == 1
        ylabel('Mean speed (cm/s)')
    end
    ht = title(sprintf('%s | p=%.3g', bodyparts{i}, p_t(i)))
    % ht = title(sprintf('%s | p<0.001', bodyparts{i}));
    set(ht,'FontWeight','Normal')
    box off
    format_axes(gca)
end
ht = sgtitle(sprintf('Paired Air-ON vs pre-Air-OFF (N=%d Mice - separate cohort)', nValid));set(ht,'FontSize',8,'FontWeight','Normal')

save_pdf(gcf, mD.pdf_folder, 'DLC_bar_air_on_vs_off.pdf', 600);


%% ---------- 1. Parameter Setup ----------
win_pre  = 5;  % seconds
win_post = 5;  % seconds
fs       = 60; % Sampling rate (frames per second)
Npre     = round(win_pre  * fs);
Npost    = round(win_post * fs);

signal   = DLC_speeds_cm(:,6); % Your data vector

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

