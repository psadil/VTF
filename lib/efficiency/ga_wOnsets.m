
options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotrange,@gaplotbestf,@gaplotscorediversity},...
    'FunctionTolerance', 1e-10,...
    'EliteCount', 5,...
    'PopulationSize', 200);

n_scan = 480;
n_reps = 4;
n_stim_type = 18;
TR = 1.5;

n_stimtime_each_max = n_scan / n_stim_type;
epoch_length = n_stimtime_each_max / n_reps;
n_events = floor(n_scan / epoch_length);
scan_time = n_scan * TR;

min_onset_diff = 2.5;

min_epoch_time_sec = 3;
max_epoch_time_sec = 20;
A = []; b = [];
lb = [ones(1, n_events), zeros(1,n_events), ones(1, n_events) * min_epoch_time_sec];
ub = [ones(1, n_events) * n_stim_type, ones(1, n_events) * scan_time, ones(1, n_events) * max_epoch_time_sec];

% which columns are integers (i.e., columns pertaining to created stim_list)
numberOfVariables = n_events;
intcon = 1:numberOfVariables;

f = @(x)simple_multiobjective_wOnsets(x, n_scan,TR, n_stim_type);
constraints = @(x)design_constraints(x, min_onset_diff);

% FitnessFunction = @simple_multiobjective;
[x,fval,exitflag,output,population,scores] = ga(f, n_events*3,A,b,[],[],lb,ub,constraints,intcon,options);


% make model

% nStims = length(x)/3;
% 
% stim_list = x(1:nStims);
% onsets = x(nStims+1:nStims*2);
% epoch_length = x(1+(2*nStims):end);
% 
% model = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets);

