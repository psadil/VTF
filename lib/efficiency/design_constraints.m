function [c, ceq] = design_constraints(x, min_onset_diff, n_dim_events, dim_sep_sec, dim_dur, epoch_length, n_stim_events)

% Problem parameters
% - minimum allowable difference between onsets

% design parameters
onsets = x(:,n_stim_events+1:n_stim_events*2);
dim_onsets = x(:,1+end-n_dim_events:end);

% calculate constraints
stim_onset_contraints = -1*(diff(onsets) - epoch_length - min_onset_diff);
dim_onset_contraints = -1*diff(dim_onsets - dim_dur - dim_sep_sec);

% 
c = [stim_onset_contraints' ; dim_onset_contraints'];
% c = stim_onset_contraints';

% No equality constraints
ceq = [];