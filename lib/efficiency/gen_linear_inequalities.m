function [A, b] = gen_linear_inequalities(n_stim_events, n_dim_events, min_onset_diff, epoch_length,dim_sep_sec, dim_dur )

A_stim_type = zeros(n_stim_events);
A_onsets = eye(n_stim_events);
for m = 1:size(A_onsets,1)
    for n = 1:size(A_onsets,2)
        if n == m+1
            A_onsets(m,n) = -1;
        end
    end
end
A_onsets(n_stim_events,n_stim_events)=0;
A_dim_onsets = eye(n_dim_events);
for m = 1:size(A_dim_onsets,1)
    for n = 1:size(A_dim_onsets,2)
        if n == m+1
            A_dim_onsets(m,n) = -1;
        end
    end
end
A_dim_onsets(n_dim_events,n_dim_events) = 0;
A = blkdiag(A_stim_type, A_onsets, A_dim_onsets);

% last element of each b component needs to be 0 (since final stimulus does
% not need to happen at some duration before a following stimulus)
b = [zeros(n_stim_events,1); ...
    [-1*repelem(min_onset_diff, n_stim_events-1)' + epoch_length; 0] ; ...
    [-1*repelem(dim_sep_sec, n_dim_events-1)' + dim_dur; 0]];


end

