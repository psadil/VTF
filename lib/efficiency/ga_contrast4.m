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
addParameter(ip, 'algorithm', 'ga', @(x) any(strcmp(x, {'shuffle','ga','block'})));
parse(ip,varargin{:});
input = ip.Results;

orientations = linspace(0, 180 - (180/input.n_orientation), input.n_orientation);
contrasts = [.2, .8];
n_stim_type = input.n_orientation * input.n_contrast;

n_TR = ceil(input.scan_time / input.TR);
n_stim_events = input.n_reps * n_stim_type;

% epoch_length_min = 1;
epoch_length_max_flip = input.epoch_length_max_flip;


options = optimoptions(@ga,'UseVectorized',false,...
    'PlotFcn',{@gaplotstopping,@gaplotbestf,@gaplotdistance},...
    'FunctionTolerance', 1e-5,...
    'EliteCount', input.EliteCount, ...'FitnessScalingFcn', @fitscalingshiftlinear,...
    'PopulationSize', input.PopulationSize,...'InitialPopulationMatrix', InitialPopulationMatrix,...
    'UseParallel',false,...
    'MaxGenerations', 1e3, 'Display', 'diagnose');


sides = [{'left'}, {'right'}];
for sub = input.participants
    for run_to_save = input.runs
        side_to_save = 1;
        while side_to_save <= 2
            
            % for dimming data, we're only optimizing during one side. The
            % other side must work with whatever happened
            if side_to_save == 1
                dim_iti = [];
                % Dim sequence parameters
                n_dim_events = floor(input.scan_time / ((input.dim_dur + input.dim_sep_max_flip)* input.flip_hz));
                
                % iti, dim_iti
                lower_bound = [ones(1,n_stim_events-1)*input.min_iti_flip,...
                    ones(1,n_dim_events-1)*input.dim_sep_min_flip];
                upper_bound = [ones(1,n_stim_events-1)*input.max_iti_flip,...
                    ones(1,n_dim_events-1)*input.dim_sep_max_flip];
                n_vars = (n_stim_events - 1) + (n_dim_events - 1);
                
                % capture cost and contraint function with extra parameters defined above
                population_parser = make_population_parser4('dim');
                
            else
                % iti only
                lower_bound = ones(1,n_stim_events-1)*input.min_iti_flip;
                upper_bound = ones(1,n_stim_events-1)*input.max_iti_flip;
                n_vars = (n_stim_events - 1);
                
                % capture cost and contraint function with extra parameters defined above
                population_parser = make_population_parser4('nodim');
                
            end
            
            switch input.algorithm
                case 'ga'
                    % reshuffle stim_order each time trial types ideally kept
                    % soemwhat equal
                    trial_types = Shuffle(repelem(1:n_stim_type, input.n_reps));
                    
                    % which columns are integers
                    intcon = 1:n_vars;
                    
                    f = @(x)contrast_objective4(x, n_TR, input.TR, n_stim_type, ...
                        n_stim_events, population_parser, epoch_length_max_flip, ...
                        input.optimality, input.flip_hz, n_dim_events, trial_types, dim_iti);
                    
                    [x, fval, exitflag, output, population, scores] = ...
                        ga(f, n_vars,[],[],[],[],lower_bound, upper_bound, [],intcon,options); %#ok<ASGLU>
                    
                    if exitflag > 0
                        % make model
                        [stim_list, onsets, epoch_length] = ...
                            population_parser(x, n_stim_events, epoch_length_max_flip, ...
                            input.flip_hz, n_dim_events, trial_types, dim_iti);
                        
                        save(['sub-', num2str(sub, '%02d'), 'task-', input.task, '_run-', num2str(run_to_save, '%02d'),...
                            '_side-', sides{side_to_save}, '_events_ga.mat'],'x','fval','output','population','scores');
                        dim_iti = onsets(stim_list == 99);
                    end
                    
                    
                case 'shuffle'
                    % reshuffle stim_order each time trial types ideally kept
                    % soemwhat equal
                    trial_types = Shuffle(repelem(1:n_stim_type, input.n_reps));
                    
                    population_parser = make_population_parser4('nodim');
                    
                    stim_iti = randsample(input.min_iti_flip:input.max_iti_flip, n_stim_events, true);
                    if side_to_save == 1
                        dim_iti = randsample(input.dim_sep_min_flip:input.dim_sep_max_flip, n_dim_events, true);
                    end
                    x = [stim_iti, dim_iti];
                    
                    % make model
                    [stim_list, onsets, epoch_length] = ...
                        population_parser(x, n_stim_events, epoch_length_max_flip, ...
                        input.flip_hz, n_dim_events, trial_types, dim_iti');
                    
                case 'block'
                    if mod(run_to_save,2) == 0
                        trial_types = repmat(1:n_stim_type, [1,input.n_reps]);
                    else
                        trial_types = repmat(n_stim_type:-1:1, [1,input.n_reps]);
                    end
                    
                    population_parser = make_population_parser4('nodim');
                    
                    stim_iti = zeros([1,n_stim_events - 1]);
                    if side_to_save == 1
                        dim_iti = randsample(input.dim_sep_min_flip:input.dim_sep_max_flip, n_dim_events, true);
                    end
                    x = [stim_iti, dim_iti];
                    
                    % make model
                    [stim_list, onsets, epoch_length] = ...
                        population_parser(x, n_stim_events, epoch_length_max_flip, ...
                        input.flip_hz, n_dim_events, trial_types, dim_iti');
            end
            % warning suppressed because SPM is saved
            SPM = DconvMTX3(stim_list, n_TR, n_stim_type, epoch_length, input.TR, onsets, input.dim_dur); %#ok<NASGU>
            save(['sub-',num2str(sub, '%02d'), '_task-', input.task, '_run-', num2str(run_to_save, '%02d'),...
                '_side-', sides{side_to_save}, '_events_SPM.mat'],'SPM');
            
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
        data_dim.onset = dim_iti';
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

