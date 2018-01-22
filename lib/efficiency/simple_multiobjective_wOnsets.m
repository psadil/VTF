function y = simple_multiobjective_wOnsets(x, n_scan, TR, n_stim_type, dim_dur, n_dim_events, epoch_length, n_stim_events)

stim_list = x(1:n_stim_events);
onsets = x(n_stim_events+1:n_stim_events*2);
dim_onsets = x(1+end-n_dim_events:end);

SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets, dim_dur, dim_onsets);

% generate contrast (for only magnitude, not derivatives)
C = eye(size(SPM.xX.X, 2)-1);
deriv1 = 2:3:size(C,1);
deriv2 = 3:3:size(C,1);
dims = (size(C,2)-2) : size(C,2);
C([deriv1,deriv2, dims],:) = [];

dFlag = 1;
EAmp = AmpEfficiency(SPM, C, dFlag);


%% output
y = -1*EAmp;

end
