
options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotrange,@gaplotbestf,@gaplotscorediversity},...
    'FunctionTolerance', 1e-10,...
    'EliteCount', 5,...
    'PopulationSize', 200,...
    'UseParallel',false, 'PenaltyFactor', 1000);
%     'MaxGenerations', 10000,...

A = []; b = [];
lb = 1;
ub = 10;

% which columns are integers (i.e., columns pertaining to created stim_list)
intcon = 1;

% capture cost and contraint function with extra parameters defined above
f = @(x)ga_wOnsets_forReps(x);

% FitnessFunction = @simple_multiobjective;
n_vars = 1;
[~,fval] = ga(f,n_vars,A,b,[],[],lb,ub,[],intcon,options);

