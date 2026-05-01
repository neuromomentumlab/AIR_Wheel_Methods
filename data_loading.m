for ii = 1:60
    pause(1);
end
%%
add_to_path_unlv
disp('Done')
%%
clear all

disp('Done');
% clc
%%
main_dir = 'E:\Data\UNLV\AIR_Wheel_Methods'; mD.main_dir = main_dir;

rdata_dir = fullfile(main_dir,'RData'); mD.rdata_dir = rdata_dir;
pdata_dir = fullfile(main_dir,'PData'); mD.pdata_dir = pdata_dir;
adata_dir = fullfile(main_dir,'AData'); mD.adata_dir = adata_dir;

animal_list = {'NML_GC_01'};
date_list = {'2025_12_16'};

fanimal = get_exp_info(mD,animal_list,date_list);

disp('Done');
%%
main_dir = 'E:\Data\UNLV\AIR_Wheel_Methods'; mD.main_dir = main_dir;

rdata_dir = fullfile(main_dir,'RData'); mD.rdata_dir = rdata_dir;
pdata_dir = fullfile(main_dir,'PData'); mD.pdata_dir = pdata_dir;
adata_dir = fullfile(main_dir,'AData'); mD.adata_dir = adata_dir;

animal_list = {'NML_M_08','NML_GC_01_R','NML_04_R','NML_05_R','NML_06_R'};
animal_list = {'NML_GC_01_R','NML_04_R','NML_05_R','NML_06_R'};
date_list = {'2025_12_16','2026_01_24','2026_01_14','2026_01_16'};

animals = get_exp_info(mD,animal_list,date_list);


% animal_listT = {'NML_GC_01','NML_04_R','NML_05_R','NML_06_R'};
% date_listT = {'2025_12_15','2026_01_23','2026_01_13','2026_01_15'};
% animalsT = get_exp_info(mD,animal_listT,date_listT);

disp('Done');
%%

rdata_dir = 'X:\Research\Neuromomentum_Cognemotion Lab\Raw_Data_Backup\Classical_Conditioning'; 
mD1.rdata_dir = rdata_dir;
pdata_dir = fullfile(main_dir,'PData'); mD1.pdata_dir = pdata_dir;
adata_dir = fullfile(main_dir,'AData'); mD1.adata_dir = adata_dir;

animal_list_1 = {'NML_04','NML_05','NML_06'};
date_list_1 = {'2026_01_24','2026_01_14','2026_01_16'};

oanimal = get_exp_info(mD1,animal_list_1,date_list_1);

disp('Done');
%%
colormaps = load('../Common/Matlab/colorblind_colormap.mat');
colormaps.colorblind = flipud(colormaps.colorblind);
mD.colors = mat2cell(colormaps.colorblind,[ones(1,size(colormaps.colorblind,1))]);%{[0 0 0],[0.1 0.7 0.3],'r','b','m','c','g','y'}; % mD.colors = getColors(10,{'w','g'});
mD.dcolors = mat2cell(distinguishable_colors(20,'w'),[ones(1,20)]);
mD.axes_font_size = 6; mD.sigColor = [0.54 0.27 0.06];
mD.asterisk_font_size = 9;
mD.shades = generate_shades(3);
mD.pdf_folder = mD.adata_dir; 
mD.pd_folder = mD.pdata_dir;
mD.magfac = 1;
mData = mD;
disp('Done');

%%
if 1
%     make_db(T_C);
    owr = 0;
    animals = process_behavior_signals(animals);
    animals = process_h264_1(animals);
end
% animalsT = process_behavior_signals(animalsT);
disp('Done');
%%
% animals = load_led_signal(animals,'intensity');
clc
animals = load_led_signal(animals,'LED_signal');
% [~,~,animals(1).b.led_sig.pupil.is_on] = find_onsets_offsets(animals(1).b.led_sig.pupil.is_on,2);
animals = load_dlc_labeled_filenames(animals);

disp('Done');
%%
animals = load_led_signal(animals,'LED_signal');

%%
animals = load_eye_pupil_roi(animals);
disp('Done');
%%
animals = load_eye_pupil_signal(animals);
disp('Done');
%% Get Video Pointers
for ii = 1
    vpa{ii} = VideoReader(fullfile(animals(ii).pdir,animals(ii).video.mp4.paws));
    vfa{ii} = VideoReader(fullfile(animals(ii).pdir,animals(ii).video.mp4.face));
    va{ii} = VideoReader(fullfile(animals(ii).pdir,animals(ii).video.mp4.pupil));
end
vpaL{1} = VideoReader(fullfile(animals(ii).pdir,'video_20251216_165824DLC_resnet50_gcamp16declimbDec18shuffle1_185000_filtered_labeled.mp4'));
disp('Done');
%%
oanimal = process_behavior_signals(oanimal);
oanimal = process_h264(oanimal);
oanimal = load_dlc_labeled_filenames(oanimal);
oanimal = load_led_signal(oanimal,'intensity');

%%
fanimal = process_behavior_signals(fanimal);
fanimal = process_h264_1(fanimal);
fanimal = load_dlc_labeled_filenames(fanimal);
fanimal = load_led_signal(fanimal,'LED_signal');
%%
clc
animal = animals(2:5);
animal = load_led_signal_s(animal,'LED_signal');
animal = load_dlc_labeled_filenames(animal);
% vp_labeled = VideoReader(animal(1).video.mp4_labeled.paws);

%%
% oanimal = animal(1);
% animal(1) = [];