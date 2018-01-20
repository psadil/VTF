
nStim = 10000;
epoch_length_sec = 2.5;
TR = 1.5;
mean_jitter = 100 - TR;
scan_time_sec = (nStim * TR) + (mean_jitter * nStim);

onsets = generate_onsets2(nStim, epoch_length_sec, scan_time_sec);

% should be about mean_jitter (is currently mean_jitter - 1)
mean(diff(onsets))
hist(diff(onsets))
