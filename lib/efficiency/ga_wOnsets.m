
options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotstopping,@gaplotbestf,@gaplotdistance},...
    'FunctionTolerance', 1e-10,...
    'EliteCount', 5,...
    'PopulationSize', 300,...
    'UseParallel',false, 'Display', 'diagnose');

n_orientation = 9;
n_contrast = 2;
orientations = linspace(0, 180 - (180/n_orientation), n_orientation);
contrasts = [.2, .8];
n_reps = 3;

scan_time = 360;
TR = 1.5;
n_scan = ceil(scan_time / TR);
n_dim_type = 1; % need to also find optimal dimming (sequence)
dim_dur = 0.4;
dim_sep_sec = 2;
n_dim_events = n_scan / (dim_dur + dim_sep_sec);
n_stim_type = n_orientation * n_contrast;

min_onset_diff = 2.5;
n_stim_events = n_reps * n_stim_type;
stimtim_max = scan_time - (n_stim_events * min_onset_diff) ;
n_stimtime_each_max = stimtim_max / n_stim_type;
max_epoch_time_sec = n_stimtime_each_max / n_reps;

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

run_to_save = 1;
for run = 1:24
    
    % n_vars = stim_events, onsets, durations, + dim_onsets;
    n_vars = n_stim_events*3 + n_dim_events;
    [x,fval,exitflag,output,population,scores] = ga(f,n_vars,A,b,[],[],lb,ub,constraints,intcon,options);
    
    if exitflag > 0
        % make model
        nStims = length(x(1:end-n_dim_events))/3;
        
        stim_list = x(1:nStims);
        onsets = x(nStims+1:nStims*2)';
        epoch_length = x(1+(2*nStims):(3*nStims));
        dim_onsets = x(1+(3*nStims):end);
        
        SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets, dim_dur, dim_onsets);
        save(['sub-01_task-contrast_run', num2str(run_to_save, '%02d'), 'events.mat'],'SPM');
        save(['sub-01_task-contrast_run', num2str(run_to_save, '%02d'), 'events_ga.mat'],'x','fval','output','population','scores');
        
        events = table();
        [events.onsets, stim_index] = sort(onsets);
        events.duration = epoch_length(stim_index)';
        events.orientation = orientations(mod(stim_list, n_orientation)+1)';
        events.contrast = contrasts((stim_list < n_orientation) + 1)';
        
        filename = [strjoin({['sub-',num2str(1, '%02d')],...
            'task-contrast', ['run-', num2str(run_to_save, '%02d')], 'events'},'_'), '.tsv'];
        
        writetable(events, filename,'FileType','text', 'Delimiter', 'tab');
        run_to_save = run_to_save + 1;
    end
end

close all;
figure
imagesc(SPM.xX.X); colormap gray
