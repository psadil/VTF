function [c, ceq] = design_constraints(x, min_onset_diff, n_stim_events)

% Problem parameters
% - minimum allowable difference between onsets

% design parameters
onsets = x(n_stim_events+1:n_stim_events*2);
epoch_length = x(2*n_stim_events+1:n_stim_events*3);

% calculate constraints
stim_onset_contraints = -1*(diff(onsets) - epoch_length(1:end-1) - min_onset_diff);

% 
c = stim_onset_contraints';

% No equality constraints
ceq = [];