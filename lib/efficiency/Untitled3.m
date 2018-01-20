
options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotrange,@gaplotbestf,@gaplotscorediversity},...
    'FunctionTolerance', 1e-10);

n_scan = 480;
n_reps = 4;
n_stim_type = 18;
TR = 1.5;
n_stimtime_each_max = n_scan / n_stim_type;
epoch_length = n_stimtime_each_max / n_reps;
n_events = floor(n_scan / epoch_length);

A = []; b = [];
lb = ones(1, n_events);
ub = ones(1, n_events) * n_stim_type;

% which columns are integers (i.e., columns pertaining to created stim_list)
numberOfVariables = n_events;
intcon = 1:numberOfVariables;

f = @(stim_list)simple_multiobjective(stim_list, n_scan,TR, n_stim_type, n_reps);

% FitnessFunction = @simple_multiobjective;
[x,fval,exitflag,output,population,scores] = ga(f, n_events*2,A,b,[],[],lb,ub,[],intcon,options);

