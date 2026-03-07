function animal = process_h264(animal,owr)

if ~exist('animal','var')
    animal = evalin('base','animal');
end

if ~exist('owr','var')
    owr = 0;
end

cams = {'face','pupil','paws'};

for an = 1:numel(animal)

    if ~isfield(animal(an),'video') || ~isfield(animal(an).video,'h264')
        continue;
    end

    % True duration from DAQ
    if isfield(animal(an),'b') && isfield(animal(an).b,'t')
        duration = animal(an).b.t(end);
    else
        disp(animal(an).ID)
        error('DAQ time not available for animal %d',an);
    end

    for c = 1:numel(cams)

        cam = cams{c};

        if ~isfield(animal(an).video.h264, cam)
            continue;
        end

        in_file = animal(an).video.h264.(cam);

        if isempty(in_file) || ~exist(in_file,'file')
            warning('process_h264:FileNotFound','Missing %s',in_file);
            continue;
        end

        [~,base,~] = fileparts(in_file);

        mp4_name = [base '.mp4'];
        out_file = fullfile(animal(an).pdir, mp4_name);


        % Skip if already exists
        if exist(out_file,'file') && owr==0
            fprintf('Skipping existing: %s\n',mp4_name);
            animal(an).video.mp4.(cam) = mp4_name;
            continue
        end

        %% -------------------------------------------------
        % STEP 1: count frames using ffprobe
        %% -------------------------------------------------

        cmd_probe = sprintf(['ffprobe -v error -count_frames ' ...
            '-select_streams v:0 -show_entries stream=nb_read_frames ' ...
            '-of default=nokey=1:noprint_wrappers=1 "%s"'], in_file);

        [status,cmdout] = system(cmd_probe);

        if status ~= 0
            warning('ffprobe failed for %s',in_file);
            continue
        end

        nframes = str2double(strtrim(cmdout));

        %% -------------------------------------------------
        % STEP 2: compute effective fps
        %% -------------------------------------------------

        fps_eff = nframes / duration;

        fprintf('\nAnimal %d  Camera %s\n',an,cam);
        fprintf('Frames: %d\n',nframes);
        fprintf('Duration: %.4f s\n',duration);
        fprintf('Effective FPS: %.4f\n',fps_eff);

        %% -------------------------------------------------
        % STEP 3: convert using correct fps
        %% -------------------------------------------------

        % cmd = sprintf(['ffmpeg -y -framerate %.6f -i "%s" ' ...
        %     '-r %.6f -pix_fmt yuv420p "%s"'], ...
        %     fps_eff, in_file, fps_eff, out_file);
        cmd = sprintf(['ffmpeg -y -fflags +genpts -r %.6f -i "%s" ' ...
               '-c:v copy -vsync 0 "%s"'], ...
               fps_eff, in_file, out_file);

        fprintf('Converting %s -> %s\n',in_file,out_file);

        status = system(cmd);

        if status ~= 0
            warning('process_h264:FFmpegError', ...
                'ffmpeg failed for %s (animal %d, cam %s)', in_file, an, cam);
            continue;
        end

        %% -------------------------------------------------
        % Store results
        %% -------------------------------------------------

        animal(an).video.mp4.(cam) = mp4_name;
        % animal(an).video.fps.(cam) = fps_eff;
        % animal(an).video.frames.(cam) = nframes;
        animal(an).video.specs.(cam).fps = fps_eff;
        animal(an).video.specs.(cam).nframes = nframes;
        filen = [base '_video_specs.mat'];
        spout_file = fullfile(animal(an).pdir, filen);
        save(spout_file,"fps_eff","nframes");
    end
end

end