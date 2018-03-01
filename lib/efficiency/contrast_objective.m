function y = contrast_objective(x, n_scan, TR, n_stim_type,...
    dim_dur, dim_onsets, n_stim_events, population_parser, epoch_length_max, optimality)


% [stim_list, onsets, epoch_length] = ...
%     population_parser(x, n_stim_events, epoch_length_max);

[stim_list, onsets, epoch_length] = ...
    population_parser(x, n_stim_events, epoch_length_max, 420, 12);


SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets, dim_dur, dim_onsets);

% generate contrast (for only magnitude, not derivatives)
C = eye(size(SPM.xX.X, 2));
deriv1 = 2:3:size(C,1);
deriv2 = 3:3:size(C,1);
intercept = size(SPM.xX.X,2);
dims = (size(C,2)-3) : (size(C,2)-1); % dimming event to remove
% dims = size(C,2)-1; % dimming event to remove
C([deriv1,deriv2,dims, intercept],:) = [];
% C([dims, intercept],:) = [];

switch optimality
    case 'D'
        dFlag = 1;
    case 'A'
        dFlag = 0;
end

EAmp = AmpEfficiency(SPM, C, dFlag);


%% output
y = -1*EAmp;

end
