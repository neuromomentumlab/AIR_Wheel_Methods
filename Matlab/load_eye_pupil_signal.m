function animals = extract_and_save_eye_pupil_signal(animals,owr)

if ~exist('owr','var')
    owr = 0;
end

for ii = 1:length(animals)
    animals(ii).epsig = process_eye_pupil(animals(ii),owr);
end


function epsig = process_eye_pupil(animal,owr)

filen = fullfile(animal(1).pdir,'eye_pupiln3.mat');
if exist(filen,'file')
    delete(filen);
end
filen = fullfile(animal(1).pdir,'eye_pupil.mat');
if exist(filen,'file') && owr == 0
    epsig = load(filen);
    return;
end
n = 0;
disp(filen);
v = VideoReader(fullfile(animal(1).pdir,animal(1).video.mp4.pupil));

%% Pupil Dynamics Extraction - Full Frame Visualization
% 1. Setup Video Reader & Calibration
px_dist = 150; 
cm_per_px = 1.27 / px_dist;
v.CurrentTime = 0; 

% 2. Initialize Storage
numFrames = floor(v.Duration * v.FrameRate);
pupil_area = nan(numFrames, 1);
pupil_center = nan(numFrames, 2);

% % 3. Define ROI (Select the eye region once)
% firstFrame = readFrame(v);
% figure(100); imshow(firstFrame);
% title('Select the Eye ROI');
% roi = round(getrect); % [xmin ymin width height]
% close(100);
roi_struct = load_eye_pupil_roi(animal);
roi(1) = roi_struct.x;
roi(2) = roi_struct.y;
roi(3) = roi_struct.width;
roi(4) = roi_struct.height;

% 4. Processing Loop
hFig = figure('Name', 'Pupil Tracking Debug - Full Frame', 'NumberTitle', 'off');
v.CurrentTime = 0; 
frameIdx = 1;
msg = ''; % Initialize for progress tracking

while hasFrame(v)
    frame = readFrame(v);
    img = rgb2gray(frame);
    eye_img = imcrop(img, roi);
    
    % Pupil segmentation
    bw = eye_img < 40; 
    bw = bwareaopen(bw, 50); 
    bw = imfill(bw, 'holes');
    
    % Identify properties
    stats = regionprops(bw, 'Area', 'Centroid', 'BoundingBox');
    
    % Display WHOLE FRAME
    % imshow(frame); hold on;
    
    if ~isempty(stats)
        [~, largestIdx] = max([stats.Area]);
        
        % Extract local coordinates
        area = stats(largestIdx).Area;
        localCentroid = stats(largestIdx).Centroid;
        localBbox = stats(largestIdx).BoundingBox;
        
        % % --- CONVERT TO GLOBAL COORDINATES ---
        % % Add the ROI offset to the local coordinates
        globalCentroid = [localCentroid(1) + roi(1), localCentroid(2) + roi(2)];
        % globalBbox = [localBbox(1) + roi(1), localBbox(2) + roi(2), localBbox(3), localBbox(4)];
        % 
        % % Draw Overlays on Full Frame
        % rectangle('Position', globalBbox, 'EdgeColor', 'r', 'LineWidth', 1.5);
        % plot(globalCentroid(1), globalCentroid(2), 'r+', 'MarkerSize', 8, 'LineWidth', 1.5);
        % 
        % Store Data
        pupil_area(frameIdx) = area * (cm_per_px^2);
        pupil_center(frameIdx, :) = globalCentroid;
    end
    
    hold off;
    % drawnow limitrate; % Faster than standard drawnow
    
    % Check if window closed
    if ~ishandle(hFig), break; end

    % Update Progress on the same line
    if mod(frameIdx, 10) == 0 || frameIdx == numFrames
        fprintf(repmat('\b', 1, length(msg)));
        prog = (frameIdx / numFrames) * 100;
        msg = sprintf('Processing Pupil Dynamics: %.1f%%', prog);
        fprintf('%s', msg);
    end
    frameIdx = frameIdx + 1;
end
fprintf('\nDone.\n');
%% 6. Plot Results (Synchronized & Formatted)
% Re-calculate time based on the actual frames processed to avoid size mismatch
actualFrames = find(~isnan(pupil_area), 1, 'last'); 
if isempty(actualFrames), actualFrames = frameIdx - 1; end

% Synchronize vectors to the same length
time_sync = (0:actualFrames-1) / v.FrameRate;
pupil_area_sync = pupil_area(1:actualFrames);
pupil_center_sync = pupil_center(1:actualFrames, :);
% filen = fullfile(animal(1).pdir,'eye_pupil.mat');
save(filen,'time_sync','pupil_area_sync');

epsig.time_sync = time_sync;
epsig.pupil_area_sync = pupil_area_sync;
close(hFig);