function ga_contrast4(varargin)

% this one doesn't attempt to optimize stimulus order. Every stim is only
% presented once or twice, so just optimize iti

% various values need to be calculated by hand. This includes 
% - n_reps (which will be based on scan_time, n_contrast, and n_orientation
% - min/max (dim) iti, based on remaining time left over
% - epoch_length_max - really, all of these relate to each other  

ip = inputParser;
addParameter(ip, 'task', 'contrast');
addParameter(ip, 'participants', 4, @isnumeric);
addParameter(ip, 'runs', 0, @isnumeric);
addParameter(ip, 'n_orientation', 12, @isnumeric);
addParameter(ip, 'n_contrast', 2, @isnumeric);
addParameter(ip, 'n_reps', 2, @isnumeric);
addParameter(ip, 'scan_time', 420, @isnumeric);
addParameter(ip, 'TR', 1, @isnumeric);
addParameter(ip, 'flip_hz', 0.1, @isnumeric);
addParameter(ip, 'min_iti_flip', 25, @isnumeric); 
addParameter(ip, 'max_iti_flip', 37, @isnumeric);
addParameter(ip, 'dims', true, @islogical);
addParameter(ip, 'dim_dur', 0.4, @isnumeric);
addParameter(ip, 'dim_sep_max_flip', 50, @isnumeric);
addParameter(ip, 'dim_sep_min_flip', 20, @isnumeric);
addParameter(ip, 'epoch_length_max_flip', 50, @isnumeric); 
addParameter(ip, 'PopulationSize', 200, @isnumeric);
addParameter(ip, 'EliteCount', 2, @isnumeric);
addParameter(ip, 'optimality', 'D', @(x) any(strcmp(x, {'D','A'})));
parse(ip,varargin{:});
input = ip.Results;

orientations = linspace(0, 180 - (180/input.n_orientation), input.n_orientation);
contrasts = [.2, .8];
n_stim_type = input.n_orientation * input.n_contrast;

n_TR = ceil(input.scan_time / input.TR);
n_stim_events = input.n_reps * n_stim_type;

% epoch_length_min = 1;
epoch_length_max_flip = input.epoch_length_max_flip;

% Dim sequence parameters
n_dim_events = floor(input.scan_time / ((input.dim_dur + input.dim_sep_max_flip)* input.flip_hz));

% iti, dim_iti
lower_bound = [ones(1,n_stim_events-1)*input.min_iti_flip,...
    ones(1,n_dim_events-1)*input.dim_sep_min_flip];
upper_bound = [ones(1,n_stim_events-1)*input.max_iti_flip,...
    ones(1,n_dim_events-1)*input.dim_sep_max_flip];
n_vars = (n_stim_events - 1) + (n_dim_events - 1);

% which columns are integers (i.e., columns pertaining to created stim_list)
intcon = 1:n_vars;

% capture cost and contraint function with extra parameters defined above
population_parser = make_population_parser4();

sides = [{'left'}, {'right'}];
for sub = input.participants
    for run_to_save = input.runs
        side_to_save = 1;
        while side_to_save <= 2
            
            % reshuffle stim_order each time trial types ideally kept
            % soemwhat equal
            trial_types = Shuffle(repelem(1:n_stim_type, input.n_reps));
            
            f = @(x)contrast_objective4(x, n_TR, input.TR, n_stim_type, ...
                n_stim_events, population_parser, epoch_length_max_flip, ...
                input.optimality, input.flip_hz, n_dim_events, trial_types);
            
            options = optimoptions(@ga,'UseVectorized',false,...
                'PlotFcn',{@gaplotstopping,@gaplotbestf,@gaplotdistance},...
                'FunctionTolerance', 1e-6,...
                'EliteCount', input.EliteCount, ...'FitnessScalingFcn', @fitscalingshiftlinear,...
                'PopulationSize', input.PopulationSize,...'InitialPopulationMatrix', InitialPopulationMatrix,...
                'UseParallel',false,...
                'MaxGenerations', 1e4, 'Display', 'diagnose');
            
            [x, fval, exitflag, output, population, scores] = ...
                ga(f, n_vars,[],[],[],[],lower_bound, upper_bound, [],intcon,options); %#ok<ASGLU>
            
            if exitflag > 0
                % make model
                [stim_list, onsets, epoch_length] = ...
                    population_parser(x, n_stim_events, epoch_length_max_flip, input.flip_hz, n_dim_events, trial_types);
                
                % warning suppressed because SPM is saved
                SPM = DconvMTX3(stim_list, n_TR, n_stim_type, epoch_length, input.TR, onsets, input.dim_dur); %#ok<NASGU>
                save(['sub-',num2str(sub, '%02d'), 'task-', input.task, '_run-', num2str(run_to_save, '%02d'),...
                    '_side-', sides{side_to_save}, '_events_SPM.mat'],'SPM');
                save(['sub-', num2str(sub, '%02d'), 'task-', input.task, '_run-', num2str(run_to_save, '%02d'),...
                    '_side-', sides{side_to_save}, '_events_ga.mat'],'x','fval','output','population','scores');
                
                events = table();
                events.onset = onsets(1:n_stim_events);
                events.duration = epoch_length;
                events.orientation = orientations(mod(stim_list(1:n_stim_events), input.n_orientation)+1)';
                events.contrast = contrasts((stim_list(1:n_stim_events) < input.n_orientation) + 1)';
                events.side = repelem(sides(side_to_save), n_stim_events)';
                events.trial = (1:n_stim_events)';
                events.subject = repelem(sub, n_stim_events)';
                
                filename = [strjoin({['sub-',num2str(sub, '%02d')],...
                    ['task-', input.task], ['run-', num2str(run_to_save, '%02d')],...
                    ['side-', sides{side_to_save}], 'events'},'_'), '.tsv'];
                
                writetable(events, filename,'FileType','text', 'Delimiter', 'tab');
                
                side_to_save = side_to_save + 1;
            end
        end
        filename_left = [strjoin({['sub-',num2str(sub, '%02d')],...
            ['task-', input.task], ['run-', num2str(run_to_save, '%02d')],...
            'side-left', 'events'},'_'), '.tsv'];
        filename_right = [strjoin({['sub-',num2str(sub, '%02d')],...
            ['task-', input.task], ['run-', num2str(run_to_save, '%02d')],...
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
        data_dim.duration = repelem(input.dim_dur, n_dim_events)';
        data_dim.orientation = repelem({'n/a'}, n_dim_events)';
        data_dim.contrast = repelem({'n/a'}, n_dim_events)';
        data_dim.side = repelem({'middle'},n_dim_events)';
        data_dim.trial = (1:n_dim_events)';
        data_dim.subject = repelem(sub, n_dim_events)';
        
        data = [data_leftright; data_dim];
        data = sortrows(data, 'onset');
        
        filename = [strjoin({['sub-',num2str(sub, '%02d')],...
            ['task-', input.task], ['run-', num2str(run_to_save, '%02d')],...
            'ga_events'},'_'), '.tsv'];
        
        writetable(data, filename, 'Filetype', 'text', 'Delimiter', 'tab');
        
    end
    
end

end

