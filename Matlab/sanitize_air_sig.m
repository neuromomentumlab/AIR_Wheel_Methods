function [air_on_idx, air_off_idx] = sanitize_air_sig(air_on_idx,air_off_idx)

% =========================================
    % FIX AIR ON/OFF ORDERING (robust)
    % =========================================
    
    % Remove any OFF that occurs before first ON
    air_off_idx(air_off_idx < air_on_idx(1)) = [];
    
    % Remove any ON that occurs after last OFF
    air_on_idx(air_on_idx > air_off_idx(end)) = [];
    
    % Make lengths equal
    nPairs = min(numel(air_on_idx), numel(air_off_idx));
    air_on_idx  = air_on_idx(1:nPairs);
    air_off_idx = air_off_idx(1:nPairs);
    
    % Safety: enforce ON < OFF for every trial
    badPairs = air_off_idx <= air_on_idx;
    
    if any(badPairs)
        warning('Fixing misordered air events...')
        air_on_idx(badPairs)  = [];
        air_off_idx(badPairs) = [];
    end
  