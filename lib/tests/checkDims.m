function checkDims(v)

w = [ 1, v', 1 ]; % auxiliary vector
runs_zeros = find(diff(w)==1)-find(diff(w)==-1);

% Desired results:
number_ones = length(runs_zeros)-1+v(1)+v(end);
% For average and median, don't count first run if v(1) is 0,
% or last run if v(end) is 0:
average_runs_zeros = mean(runs_zeros(2-v(1):end-1+v(end))); 
median_runs_zeros = median(runs_zeros(2-v(1):end-1+v(end)));



end

