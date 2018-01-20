function [c, ceq] = design_constraints(x, min_onset_diff)

% Problem parameters
% - minimum allowable difference between onsets

% design parameters
nStims = length(x)/3;
onsets = x(nStims+1:nStims*2);
epoch_length = x(1+(2*nStims):end);

% calculate constraints
c = -1*diff(onsets + epoch_length) + min_onset_diff;

% No equality constraints
ceq = [];