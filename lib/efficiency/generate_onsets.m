function onsets = generate_onsets(nStims, epoch_length_sec, scan_time_sec, mean_jitter)
% generate onsets as a gamma distribution, which is the sum of many
% exponentials. In this way, the gamma can be truncated at a maximum which
% allows the total run duration not to exceed some specified value
% (determined by the amount and length of trials)

stim_time_sec = nStims * epoch_length_sec;
max_jitter_time = scan_time_sec - stim_time_sec;
min_jitter_time = 2.5 * nStims; % to avoid nonlinearity in BOLD

jitter_distribution = makedist('Gamma', 'a',nStims,'b', mean_jitter);
jitter_distribution = truncate(jitter_distribution, min_jitter_time, max_jitter_time);
jitters = random(jitter_distribution, [1,1]);

% jitter_distribution = makedist('Exponential', 'mu', mean_jitter);
% jitters = random(jitter_distribution, [nStims,1]);

simplex = r_dirichlet(nStims);

% time from beginning of scan at which trials start
onsets = jitters * simplex + epoch_length_sec .* (0:nStims-1)';
% onsets = cumsum(jitters);

end

function simplex = r_dirichlet(k)
% https://en.wikipedia.org/wiki/Dirichlet_distribution#Gamma_distribution

pd = makedist('Gamma', 'a', k,'b',1);
simplex_raw = random(pd, [k, 1]);

simplex = simplex_raw ./ sum(simplex_raw);

end