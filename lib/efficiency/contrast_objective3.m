function y = contrast_objective3(x, n_scan, TR, n_stim_type,...
     n_stim_events, population_parser, epoch_length_max, optimality, resolution, n_dim_events)


[stim_list, onsets, epoch_length] = ...
    population_parser(x, n_stim_events, epoch_length_max, resolution, n_dim_events);

SPM = DconvMTX3(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets, 0.4);

% generate contrast (for only magnitude, not derivatives)
C = eye(size(SPM.xX.X, 2));
deriv1 = 2:3:size(C,1);
deriv2 = 3:3:size(C,1);
intercept = size(SPM.xX.X,2);
dims = (size(C,2)-3) : (size(C,2)-1); % dimming event to remove
C([deriv1,deriv2, intercept, dims],:) = [];

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
