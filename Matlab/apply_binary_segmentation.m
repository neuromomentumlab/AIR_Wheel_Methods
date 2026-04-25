function binary_signal = apply_binary_segmentation(t_led, s_led_raw)
    % t_led: Time vector
    % s_led_raw: Raw intensity vector 
    
    % 1. Calculate a robust threshold
    % Percentiles handle cases where the LED is OFF most of the time
    floor_val = prctile(s_led_raw, 10);
    peak_val = prctile(s_led_raw, 90);
    threshold = (floor_val + peak_val) / 2;

    % 2. Create the binary signal
    % s_led_raw > threshold returns a logical array (0 and 1)
    binary_signal = double(s_led_raw > threshold);

    % 3. Clean up single-sample glitches (Morphological opening/closing)
    % This removes "spikes" and fills "tiny holes" that are only 1 sample wide
    binary_signal = medfilt1(binary_signal, 3);

    % Ensure the output is the same dimensions as the input
    binary_signal = reshape(binary_signal, size(s_led_raw));
end
