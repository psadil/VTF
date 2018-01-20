function y = simple_multiobjective_wOnsets(x, n_scan, TR, n_stim_type)

nStims = length(x)/3;

stim_list = x(1:nStims);
onsets = x(nStims+1:nStims*2);
epoch_length = x(1+(2*nStims):end);

SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets);

% generate contrast (for only magnitude, not derivatives)
C = eye(n_stim_type*3);
deriv1 = 2:3:size(C,1);
deriv2 = 3:3:size(C,1);
C([deriv1,deriv2],:) = [];

dFlag = 1;
EAmp = AmpEfficiency(SPM, C, dFlag);


%% output
if EAmp > 0
    y = 1/EAmp;
else
    y = inf;
end

end
