function [onsets, offsets, bin_sig] = find_onsets_offsets(signal, discard)

% ------------------------------------------------------------
% FIND_ONSETS_OFFSETS
% Detects onset and offset indices from a signal.
%
% INPUTS
% signal   : continuous or binary signal
% discard  : indices of events to remove (optional)
%
% OUTPUTS
% onsets   : onset indices
% offsets  : offset indices
% bin_sig  : binarized signal after removing discarded events
% ------------------------------------------------------------

% If signal is not binary, binarize
if ~islogical(signal)
    thresh = mean(signal);
    bin_sig = signal > thresh;
else
    bin_sig = signal;
end

bin_sig = bin_sig(:);  % ensure column

% Detect transitions
d = diff([0; bin_sig; 0]);

onsets  = find(d == 1);
offsets = find(d == -1) - 1;

% ------------------------------------------------------------
% Optional discard
% ------------------------------------------------------------

if nargin > 1 && ~isempty(discard)

    % Remove requested events
    onsets(discard)  = [];
    offsets(discard) = [];

    % Rebuild binary signal
    bin_sig = zeros(size(bin_sig));

    for i = 1:length(onsets)
        bin_sig(onsets(i):offsets(i)) = 1;
    end

end

end

