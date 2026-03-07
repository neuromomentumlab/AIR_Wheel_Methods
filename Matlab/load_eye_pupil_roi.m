function animals = load_eye_pupil_roi(animals,owr)

if ~exist('owr','var')
    owr = 0;
end

if length(animals) > 1
    for ii = 1:length(animals)
        animals(ii).epsig.roi = load_eye_pupil(animals(ii),owr);
    end
else
    animals = load_eye_pupil(animals,owr);
end


function roi_struct = load_eye_pupil(animal,owr)

json_filename = fullfile(animal(1).pdir,'eye_pupil_roi.json');
if exist(json_filename,'file') && owr == 0
    % Read JSON file
    json_text = fileread(json_filename);
    roi_struct = jsondecode(json_text);
    disp(roi_struct)
    return;
end

v = VideoReader(fullfile(animal(1).pdir,animal(1).video.mp4.pupil));

% 3. Define ROI (Select the eye region once)
firstFrame = readFrame(v);
figure(100); imshow(firstFrame);
title('Select the Eye ROI');
roi = round(getrect); % [xmin ymin width height]
close(100);

% Convert ROI into a structured format
roi_struct = struct();
roi_struct.x = roi(1);
roi_struct.y = roi(2);
roi_struct.width = roi(3);
roi_struct.height = roi(4);

% Convert to JSON
json_text = jsonencode(roi_struct);

% Save JSON file
% json_filename = 'eye_roi.json';
fid = fopen(json_filename, 'w');
fprintf(fid, '%s', json_text);
fclose(fid);

disp(['ROI saved to ', json_filename]);
