function make_alignment_movie(animal, vp, vf, va, trialNum, outFile)
% vp = pupil VideoReader
% vf = face VideoReader
% va = paws VideoReader
% trialNum = air/LED trial number
% outFile = optional mp4 filename

if nargin < 6
    outFile = '';
end

preSec  = 7.3886 - 0;
postSec = 21.298 - 7.5886;

% preSec  = 0.5;
% postSec = 0.5;

fpsOut  = 60;

vids.paws  = vp;
vids.face  = vf;
vids.pupil = va;

cams = {'paws','face','pupil'};

%% --- find LED onset frame separately for each camera ---
for c = 1:numel(cams)

    cam = cams{c};

    T = animal.b.led_sig.(cam);
    led_bin = double(T.is_on(:));

    dled = diff([0; led_bin]);
    led_on_frames = find(dled == 1);

    if trialNum > numel(led_on_frames)
        error('Trial %d not found for %s camera. Only %d LED onsets found.', ...
            trialNum, cam, numel(led_on_frames));
    end

    f0.(cam) = led_on_frames(trialNum);   % event frame for this camera
    fps.(cam) = vids.(cam).FrameRate;

end
% f0.paws  = 436;
% f0.face  = 439;
% f0.pupil = 441;

%% --- DAQ onset only for speed alignment ---
air = animal.b.air_bin(:);
tm  = animal.b.tm(:) * 60;   % minutes to seconds

dair = diff([0; air]);
daq_onsets = find(dair == 1);
air_on_times = tm(daq_onsets);

t0_daq = air_on_times(trialNum);

%% --- speed signal ---
speed_t = animal.b.t(:);          % seconds
speed_y = animal.b.fSpeed(:);     % cm/s

%% --- prepare figure ---
hf = figure(100);clf;
set(hf,'Color','k','Position',[100 100 1400 800]);
% set(hf,'Color','k');

axPaws  = subplot(2,2,1);
axFace  = subplot(2,2,2);
axPupil = subplot(2,2,3);
axSpeed = subplot(2,2,4);

%% --- optional video writer ---
saveMovie = ~isempty(outFile);

if saveMovie
    vw = VideoWriter(outFile,'MPEG-4');
    vw.FrameRate = fpsOut;
    open(vw);
end

%% --- relative movie timeline ---
tRelVec = -preSec : 1/fpsOut : postSec;

for k = 1:numel(tRelVec)

    tRel = tRelVec(k);

    % Frame index in each video using its own true frame rate
    frameIdx.paws  = f0.paws  + round(tRel * fps.paws);
    frameIdx.face  = f0.face  + round(tRel * fps.face);
    frameIdx.pupil = f0.pupil + round(tRel * fps.pupil);

    framePaws  = read_frame_idx(vids.paws,  frameIdx.paws);
    frameFace  = read_frame_idx(vids.face,  frameIdx.face);
    framePupil = read_frame_idx(vids.pupil, frameIdx.pupil);

    %% --- Paws ---
    axes(axPaws); cla;
    imshow(framePaws);
    title(sprintf('Paws | t = %.2f s | frame %d', ...
        tRel, frameIdx.paws), 'Color','w');

    %% --- Face ---
    axes(axFace); cla;
    imshow(frameFace);
    title(sprintf('Face | t = %.2f s | frame %d', ...
        tRel, frameIdx.face), 'Color','w');

    %% --- Pupil ---
    axes(axPupil); cla;
    imshow(framePupil);
    title(sprintf('Pupil | t = %.2f s | frame %d', ...
        tRel, frameIdx.pupil), 'Color','w');

    %% --- Speed plot ---
    axes(axSpeed); cla; hold on;

    plot(speed_t - t0_daq, speed_y, 'LineWidth', 1.5);
    plot(speed_t - t0_daq, air * 11, 'LineWidth', 1.5);
    xline(0,'--','Air onset','LineWidth',1.2);
    xline(tRel,'r','LineWidth',1.2);

    xlim([-preSec postSec]);

    yMin = min(speed_y);
    yMax = max(speed_y);
    if yMin == yMax
        yMax = yMin + 1;
    end
    ylim([yMin yMax * 1.05]);

    xlabel('Time from air onset (s)');
    ylabel('Speed (cm/s)');
    title(sprintf('Speed | trial %d', trialNum));
    
    set(gca, ...
    'Color','k', ...
    'XColor','w', ...
    'YColor','w', ...
    'GridColor','c', ...
    'MinorGridColor','g');

    grid on;

    drawnow;

    if saveMovie
        F = getframe(hf);
        writeVideo(vw,F);
    end
end

if saveMovie
    close(vw);
    fprintf('Saved movie: %s\n', outFile);
end
close(hf);
end


function frame = read_frame_idx(vObj, frameIdx)
% Reads frame by frame index using VideoReader time backend.

frameIdx = max(1, round(frameIdx));

tSec = (frameIdx - 1) / vObj.FrameRate;
tSec = max(0, min(tSec, vObj.Duration));

vObj.CurrentTime = double(tSec);

if hasFrame(vObj)
    frame = readFrame(vObj);
else
    vObj.CurrentTime = max(0, vObj.Duration - 1/vObj.FrameRate);
    frame = readFrame(vObj);
end

end