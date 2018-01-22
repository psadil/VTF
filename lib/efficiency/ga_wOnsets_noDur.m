

n_orientation = 12;
n_contrast = 2;
orientations = linspace(0, 180 - (180/n_orientation), n_orientation);
contrasts = [.2, .8];
n_reps = 2;

scan_time = 420;
TR = 1.5;
n_scan = ceil(scan_time / TR);
n_dim_type = 1; % need to also find optimal dimming (sequence)
dim_dur = 0.4;
dim_sep_sec = 4;
n_dim_events = floor(n_scan / (dim_dur + dim_sep_sec));
n_stim_type = n_orientation * n_contrast;

min_onset_diff = 2.5;
epoch_length = 5.5;
isi = min_onset_diff + epoch_length;
n_stim_events = n_reps * n_stim_type;
stimtime = (n_stim_events * min_onset_diff) + (epoch_length * n_stim_events);


% stim_type, onsets, dim_onsets
hrf_lag = 15;
lb = [ones(1, n_stim_events), zeros(1,n_stim_events),...
    zeros(1,n_dim_events)];
ub = [ones(1, n_stim_events) * n_stim_type, ones(1, n_stim_events) * scan_time - epoch_length - hrf_lag,...
    ones(1, n_dim_events) * scan_time - dim_dur];

% which columns are integers (i.e., columns pertaining to created stim_list)
intcon = 1:n_stim_events;

% capture cost and contraint function with extra parameters defined above
f = @(x)simple_multiobjective_wOnsets(x, n_scan,TR, n_stim_type, dim_dur, n_dim_events, epoch_length, n_stim_events);
% [A, b] = gen_linear_inequalities(n_stim_events, n_dim_events, min_onset_diff, epoch_length,dim_sep_sec, dim_dur );
constraints = @(x)design_constraints(x, min_onset_diff, n_dim_events, dim_sep_sec, dim_dur, epoch_length, n_stim_events);

PopulationSize = 300;
InitialPopulationVector = [Shuffle(repelem(1:n_stim_type, n_reps)), ...
    linspace(0,scan_time - epoch_length - hrf_lag, n_stim_events ), ...
    linspace(0,scan_time - dim_dur,n_dim_events)];

InitialPopulationMatrix = repmat(InitialPopulationVector, [PopulationSize, 1]);

options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotstopping,@gaplotbestf,@gaplotdistance},...
    'FunctionTolerance', 1e-10,...
    'EliteCount', 5,...
    'PopulationSize', PopulationSize,'InitialPopulationMatrix', InitialPopulationMatrix,...
    'UseParallel',false,...
    'MaxGenerations', 1e4, 'Display', 'diagnose');

run_to_save = 1;
for run = 1:1
    
    % n_vars = stim_events, onsets, durations, + dim_onsets;
    n_vars = n_stim_events*2 + n_dim_events;
    [x,fval,exitflag,output,population,scores] = ga(f,n_vars,[],[],[],[],lb,ub,constraints,intcon,options);
    
    if exitflag > 0
        % make model
        stim_list = x(1:n_stim_events);
        onsets = x(n_stim_events+1:n_stim_events*2)';
        dim_onsets = x(1+(2*n_stim_events):end);
        
        SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets, dim_dur, dim_onsets);
        save(['sub-01_task-contrast_run', num2str(run_to_save, '%02d'), '_events_SPM.mat'],'SPM');
        save(['sub-01_task-contrast_run', num2str(run_to_save, '%02d'), '_events_ga.mat'],'x','fval','output','population','scores');
        
        events = table();
        [events.onsets, stim_index] = sort(onsets);
        events.duration = repelem(epoch_length, n_stim_events)';
        events.orientation = orientations(mod(stim_list, n_orientation)+1)';
        events.contrast = contrasts((stim_list < n_orientation) + 1)';
        
        filename = [strjoin({['sub-',num2str(1, '%02d')],...
            'task-contrast', ['run-', num2str(run_to_save, '%02d')], 'events'},'_'), '.tsv'];
        
        writetable(events, filename,'FileType','text', 'Delimiter', 'tab');
        run_to_save = run_to_save + 1;
        
        close all;
        figure
        imagesc(SPM.xX.X); colormap gray
        
    end
end

