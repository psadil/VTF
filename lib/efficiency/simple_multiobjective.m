function y = simple_multiobjective(stim_list, n_scan,TR, n_stim_type, n_reps)

n_stimtime_each_max = n_scan / n_stim_type;
epoch_length = n_stimtime_each_max / n_reps;

model = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR);

% exclude intercept from model
X = model(:,1:end-1);
% X = model(:,1:end-1) - mean(model(:,1:end-1),2);
% X = model;

% generate contrast (for only magnitude, not derivatives)
% C = [eye(n_stim_type*3), zeros(n_stim_type*3,1)];
C = eye(n_stim_type*3);
deriv1 = 2:3:size(C,1);
deriv2 = 3:3:size(C,1);
C([deriv1,deriv2],:)=[];

dFlag = 1;
EAmp = AmpEfficiency(X, C, dFlag);


%% output
if EAmp > 0
    y = 1/EAmp;
else
    y = inf;
end

end
