function animal = load_led_signal(animal,suffix)

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
        csv_name = [base sprintf('_%s.csv',suffix)];
        out_file_csv = fullfile(animal(an).pdir, csv_name);
        disp(out_file_csv);
        animal(an).video.led.(cam) = out_file_csv;
        fps = animal(an).video.specs.(cam).fps;
        animal(an).b.led.(cam) = readtable(out_file_csv);
        animal(an).b.led_sig.(cam) = extract_led_from_roi_M(animal(an).b.led.(cam), fps);
    end
end
end