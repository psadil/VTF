
n_orientation = 12;
n_contrast = 2;
orientations = linspace(0, 180 - (180/n_orientation), n_orientation);
contrasts = [.2, .8];
n_reps = 2;
n_stim_type = n_orientation * n_contrast;

scan_time = 420;
TR = 1.5;
n_scan = ceil(scan_time / TR);
sn_stim_type = n_orientation * n_contrast;
n_stim_events = n_reps * n_stim_type;
hrf_lag = 15;

min_onset_diff = 2.5;
slack = 0.5;
stimtime = scan_time - (min_onset_diff * n_stim_events) - (n_stim_events * slack) - hrf_lag;
epoch_length_max = stimtime / n_stim_events; % isi = min_onset_diff + epoch_length_max;
epoch_length_min = 1;

% stim_type, onsets, durations
lb = [ones(1, n_stim_events), zeros(1,n_stim_events),...
    ones(1, n_stim_events) * epoch_length_min];
ub = [ones(1, n_stim_events) * n_stim_type, ones(1, n_stim_events) * scan_time - epoch_length_max - hrf_lag,...
    ones(1, n_stim_events) * epoch_length_max];

% which columns are integers (i.e., columns pertaining to created stim_list)
intcon = 1:n_stim_events;

dim_dur = 0.4;
dim_sep_max = 4;
dim_sep_min = 3;
n_dim_events = floor(scan_time / (dim_dur + dim_sep_max));
dim_diffs = dim_sep_min + (dim_sep_max - dim_sep_min)*rand([n_dim_events,1]);
dim_onsets = cumsum(dim_diffs)' + (dim_dur*(0:n_dim_events-1));

% capture cost and contraint function with extra parameters defined above
f = @(x)simple_multiobjective_wOnsets(x, n_scan,TR, n_stim_type, dim_dur, dim_onsets, n_stim_events);
constraints = @(x)design_constraints(x, min_onset_diff, n_stim_events);

PopulationSize = 300;

sides = [{'left'}, {'right'}];
for sub = 4:8
    for run_to_save = 1:10
        side_to_save = 1;
        while side_to_save <= 2
            
            % reshuffle stim_order each time
            InitialPopulationVector = [Shuffle(repelem(1:n_stim_type, n_reps)), ...
                linspace(0,scan_time - epoch_length_max - hrf_lag, n_stim_events ), ...
                repelem(epoch_length_max, n_stim_events)];
            
            InitialPopulationMatrix = repmat(InitialPopulationVector, [PopulationSize, 1]);
            
            options = optimoptions(@ga,'UseVectorized',false,...
                'PlotFcn',{@gaplotstopping,@gaplotbestf,@gaplotdistance},...
                'FunctionTolerance', 1e-6,...
                'EliteCount', 5,...
                'PopulationSize', PopulationSize,'InitialPopulationMatrix', InitialPopulationMatrix,...
                'UseParallel',false,...
                'MaxGenerations', 1e3, 'Display', 'diagnose');
            
            % n_vars = stim_events, onsets, durations;
            n_vars = n_stim_events*3;
            [x,fval,exitflag,output,population,scores] = ga(f,n_vars,[],[],[],[],lb,ub,constraints,intcon,options);
            
            if exitflag > 0
                % make model
                stim_list = x(1:n_stim_events);
                onsets = x(n_stim_events+1:n_stim_events*2)';
                epoch_length = x(2*n_stim_events+1:n_stim_events*3)';
                
                SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, TR, onsets, dim_dur, dim_onsets);
                save(['sub-',num2str(sub, '%02d'), '_task-contrast_run', num2str(run_to_save, '%02d'),...
                    '_side-', sides{side_to_save}, '_events_SPM.mat'],'SPM');
                save(['sub-', num2str(sub, '%02d'), '_task-contrast_run', num2str(run_to_save, '%02d'),...
                    '_side-', sides{side_to_save}, '_events_ga.mat'],'x','fval','output','population','scores');
                
                events = table();
                events.onset = onsets;
                events.duration = epoch_length;
                events.orientation = orientations(mod(stim_list, n_orientation)+1)';
                events.contrast = contrasts((stim_list < n_orientation) + 1)';
                events.side = repelem(sides(side_to_save), n_stim_events)';
                events.trial = (1:n_stim_events)';
                events.subject = repelem(sub, n_stim_events)';
                
                filename = [strjoin({['sub-',num2str(sub, '%02d')],...
                    'task-contrast', ['run-', num2str(run_to_save, '%02d')],...
                    ['side-', sides{side_to_save}], 'events'},'_'), '.tsv'];
                
                writetable(events, filename,'FileType','text', 'Delimiter', 'tab');
                
                side_to_save = side_to_save + 1;
            end
        end
        filename_left = [strjoin({['sub-',num2str(sub, '%02d')],...
            'task-contrast', ['run-', num2str(run_to_save, '%02d')],...
            'side-left', 'events'},'_'), '.tsv'];
        filename_right = [strjoin({['sub-',num2str(sub, '%02d')],...
            'task-contrast', ['run-', num2str(run_to_save, '%02d')],...
            'side-right', 'events'},'_'), '.tsv'];
        data_left = struct2table(tdfread(filename_left, 'tab'));
        data_right = struct2table(tdfread(filename_right, 'tab'));
        
        % need to store missing values as n/a, so values with missing data must
        % be stored as characters
        data_left.side = num2cell(data_left.side,2);
        data_right.side = num2cell(data_right.side,2);
        data_leftright = [data_left; data_right];
        data_leftright.orientation = strtrim(cellstr(num2str(data_leftright.orientation)));
        data_leftright.contrast = strtrim(cellstr(num2str(data_leftright.contrast)));
        
        data_dim = table();
        data_dim.onset = dim_onsets';
        data_dim.duration = repelem(dim_dur, n_dim_events)';
        data_dim.orientation = repelem({'n/a'}, n_dim_events)';
        data_dim.contrast = repelem({'n/a'}, n_dim_events)';
        data_dim.side = repelem({'middle'},n_dim_events)';
        data_dim.trial = (1:n_dim_events)';
        data_dim.subject = repelem(sub, n_dim_events)';
        
        data = [data_leftright; data_dim];
        data = sortrows(data, 'onset');
        
        filename = [strjoin({['sub-',num2str(sub, '%02d')],...
            'task-contrast', ['run-', num2str(run_to_save, '%02d')],...
            'ga_events'},'_'), '.tsv'];
        
        writetable(data, filename, 'Filetype', 'text', 'Delimiter', 'tab');
        
    end
    
end