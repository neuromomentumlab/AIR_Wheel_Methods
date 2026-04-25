function [s_led_bin, out] = binarize_led_with_background(t_led, s_led_raw, s_led_raw_B, varargin)

p = inputParser;
addParameter(p, 'Method', 'subtract');   % 'subtract' or 'ratio'
addParameter(p, 'SmoothFrames', 3);
addParameter(p, 'ThresholdMethod', 'otsu'); % 'otsu' or 'zscore'
addParameter(p, 'ZThresh', 3);
addParameter(p, 'MinOnSec', 0.10);
addParameter(p, 'MinOffSec', 0.10);
addParameter(p, 'Plot', true);
parse(p, varargin{:});

method = p.Results.Method;

t_led = double(t_led(:));
led = double(s_led_raw(:));
bg  = double(s_led_raw_B(:));

switch lower(method)
    case 'subtract'
        x = led - bg;
    case 'ratio'
        x = led ./ (bg + eps);
    otherwise
        error('Method must be subtract or ratio');
end

% light smoothing only
if p.Results.SmoothFrames > 1
    x_smooth = movmedian(x, p.Results.SmoothFrames);
else
    x_smooth = x;
end

switch lower(p.Results.ThresholdMethod)
    case 'otsu'
        xn = rescale(x_smooth);
        thr = graythresh(xn);
        s_led_bin = xn > thr;

    case 'zscore'
        z = (x_smooth - median(x_smooth,'omitnan')) ./ mad(x_smooth,1);
        thr = p.Results.ZThresh;
        s_led_bin = z > thr;

    otherwise
        error('ThresholdMethod must be otsu or zscore');
end

dt = median(diff(t_led),'omitnan');
minOnFrames  = max(1, round(p.Results.MinOnSec/dt));
minOffFrames = max(1, round(p.Results.MinOffSec/dt));

% remove tiny ON glitches
s_led_bin = bwareaopen(s_led_bin, minOnFrames);

% fill tiny OFF gaps
s_led_bin = ~bwareaopen(~s_led_bin, minOffFrames);

out.corrected_trace = x;
out.smoothed_trace = x_smooth;
out.threshold = thr;
out.method = method;
out.t_led = t_led;

if p.Results.Plot
    figure; hold on
    plot(t_led, led)
    plot(t_led, bg)
    plot(t_led, x_smooth)
    yyaxis right
    plot(t_led, double(s_led_bin), 'k')
    legend('LED raw','Background raw','Corrected','Binary')
end

end