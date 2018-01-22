function fval = ga_wOnsets_forReps(x)

options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotrange,@gaplotbestf,@gaplotmaxconstr},...
    'FunctionTolerance', 1e-10,...
    'EliteCount', 5,...
    'PopulationSize', 200,...
    'UseParallel',false, 'PenaltyFactor', 1000);

n_scan = 480;
n_reps = x;
dim_dur = 0.4;
dim_sep_sec = 2;
n_dim_events = n_scan / (dim_dur + dim_sep_sec);
n_stim_type = 18;
TR = 1.5;

scan_time = n_scan * TR;
n_stimtime_each_max = scan_time / n_stim_type;
max_epoch_time_sec = n_stimtime_each_max / n_reps;
n_stim_events = floor(scan_time / max_epoch_time_sec);

min_onset_diff = 2.5;
min_epoch_time_sec = 0.8;
A = []; b = [];
% stim_type, onsets, epoch_length, dim_onsets
lb = [ones(1, n_stim_events), zeros(1,n_stim_events),...
    ones(1, n_stim_events) * min_epoch_time_sec,  zeros(1,n_dim_events)];
ub = [ones(1, n_stim_events) * n_stim_type, ones(1, n_stim_events) * scan_time - max_epoch_time_sec,...
    ones(1, n_stim_events) * max_epoch_time_sec, ones(1, n_dim_events) * scan_time - dim_dur];

% which columns are integers (i.e., columns pertaining to created stim_list)
intcon = 1:n_stim_events;

% capture cost and contraint function with extra parameters defined above
f = @(x)simple_multiobjective_wOnsets(x, n_scan,TR, n_stim_type, dim_dur, n_dim_events);
constraints = @(x)design_constraints(x, min_onset_diff, n_dim_events, dim_sep_sec, dim_dur);

% FitnessFunction = @simple_multiobjective;
n_vars = n_stim_events*3 + n_dim_events;
[~,fval] = ga(f,n_vars,A,b,[],[],lb,ub,constraints,intcon,options);

end