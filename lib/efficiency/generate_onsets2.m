function onsets = generate_onsets2(nStims, epoch_length_sec, scan_time_sec)
% generate onsets as a gamma distribution, which is the sum of many
% exponentials. In this way, the gamma can be truncated at a maximum which
% allows the total run duration not to exceed some specified value
% (determined by the amount and length of trials)

stim_time_sec = nStims * epoch_length_sec;
jitter_time = scan_time_sec - stim_time_sec;

simplex = r_dirichlet(nStims);

% time from beginning of scan at which trials start
onsets = cumsum(jitter_time * simplex) + epoch_length_sec .* (0:nStims-1)';

end

function simplex = r_dirichlet(k)
% https://en.wikipedia.org/wiki/Dirichlet_distribution#Gamma_distribution

pd = makedist('Gamma', 'a', k,'b',1);
simplex_raw = random(pd, [k, 1]);

simplex = simplex_raw ./ sum(simplex_raw);

end