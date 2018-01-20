
spm_jobman('initcfg')
spm('defaults', 'FMRI');

n_scan = 420;
n_stim_type = 18;
TR = 1.5;
n_stimtime_each_max = n_scan / n_stim_type;

n_reps = 3;
epoch_length = n_stimtime_each_max / n_reps;

n_events = floor(n_scan / epoch_length);
% n_reps = floor(n_events / n_stim_type);
stim_list = Shuffle(repelem(1:n_stim_type, n_reps));

model = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR,1);







