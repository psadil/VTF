function ga_contrast_shuffle(varargin)

ip = inputParser;
addParameter(ip, 'participants', 4, @isnumeric);
addParameter(ip, 'runs', 0:10, @isnumeric);
addParameter(ip, 'n_orientation', 12, @isnumeric);
addParameter(ip, 'n_contrast', 2, @isnumeric);
addParameter(ip, 'n_reps', 2, @isnumeric);
addParameter(ip, 'scan_time', 420, @isnumeric);
addParameter(ip, 'TR', 1, @isnumeric);
addParameter(ip, 'hrf_lag', 0, @isnumeric);
addParameter(ip, 'min_onset_diff', 3, @isnumeric);
addParameter(ip, 'max_onset_diff', 5, @isnumeric);
addParameter(ip, 'dim_dur', 0.4, @isnumeric);
addParameter(ip, 'dim_sep_max', 5, @isnumeric);
addParameter(ip, 'dim_sep_min', 2, @isnumeric);
addParameter(ip, 'duration', false, @islogical); % whether to try to optimize duration
addParameter(ip, 'epoch_length_max', 4.5, @isnumeric); % only takes effect when duration == false
addParameter(ip, 'PopulationSize', 1, @isnumeric); 
addParameter(ip, 'EliteCount', 50, @isnumeric); 
addParameter(ip, 'optimality', 'D', @(x) any(strcmp(x, {'D','A'}))); 
parse(ip,varargin{:});
input = ip.Results;

orientations = linspace(0, 180 - (180/input.n_orientation), input.n_orientation);
contrasts = [.2, .8];
n_stim_type = input.n_orientation * input.n_contrast;

n_scan = ceil(input.scan_time / input.TR);
n_stim_events = input.n_reps * n_stim_type;

epoch_length_min = 1;
if input.duration
    stimtime = input.scan_time - (input.min_onset_diff * (n_stim_events - 1)) - input.hrf_lag;
    epoch_length_max = stimtime / n_stim_events; 
    
    % stim_type, onsets, durations
    lb = [ones(1, n_stim_events), zeros(1,n_stim_events),...
        ones(1, n_stim_events) * epoch_length_min];
    ub = [ones(1, n_stim_events) * n_stim_type,...
        ones(1, n_stim_events) * input.scan_time - epoch_length_max - input.hrf_lag,...
        ones(1, n_stim_events) * epoch_length_max];
    n_vars = n_stim_events*3;
    
else
    epoch_length_max = input.epoch_length_max;
    
    % stim_type, onsets
    lb = [ones(1, n_stim_events), zeros(1,n_stim_events)];
    ub = [ones(1, n_stim_events) * n_stim_type,...
        ones(1, n_stim_events) * input.scan_time - epoch_length_max - input.hrf_lag];
    n_vars = n_stim_events*2;
end

% which columns are integers (i.e., columns pertaining to created stim_list)
intcon = 1:n_stim_events;

% Dim sequence parameters
n_dim_events = floor(input.scan_time / (input.dim_dur + input.dim_sep_min));
% dim_diffs = input.dim_sep_min + (input.dim_sep_max - input.dim_sep_min)*rand([n_dim_events,1]);
dim_diffs = randsample(input.dim_sep_min : 0.1 : input.dim_sep_max, n_dim_events, true);
dim_onsets = cumsum(dim_diffs) + (input.dim_dur*(0:n_dim_events-1));
dim_onsets = dim_onsets(dim_onsets < input.scan_time - input.dim_dur);
n_dim_events = length(dim_onsets);

% capture cost and contraint function with extra parameters defined above

design_constraints_fcn = make_design_constraints(input.duration);
constraints = @(x)design_constraints_fcn(x, input.min_onset_diff, n_stim_events, epoch_length_max);

population_parser = make_population_parser(input.duration);

f = @(x)contrast_objective(x, n_scan, input.TR, n_stim_type, ...
    input.dim_dur, dim_onsets, n_stim_events, population_parser, epoch_length_max, input.optimality);

sides = [{'left'}, {'right'}];
for sub = input.participants
    for run_to_save = input.runs
        side_to_save = 1;
        while side_to_save <= 2
            
            % reshuffle stim_order each time trial types ideally kept
            % soemwhat equal
            trial_types = NaN(input.PopulationSize, n_stim_events);
            for i = 1:input.PopulationSize
                trial_types(i,:) = Shuffle(repelem(1:n_stim_type, input.n_reps));
            end
            % onsets are hardest to guess. these are just forced
            diffs = randsample(input.min_onset_diff : 0.1 : input.max_onset_diff, n_stim_events, true);
            %             diffs = input.min_onset_diff + (input.max_onset_diff - input.min_onset_diff)*rand([n_stim_events,1]);
            onsets = cumsum(diffs) + (epoch_length_max*(0:n_stim_events-1));
%             onsets = linspace(0,input.scan_time - epoch_length_max - input.hrf_lag, n_stim_events );
            %             onsets = repmat(onsets, [input.PopulationSize, 1]);
            if input.duration
                durations = epoch_length_min + ...
                    (epoch_length_max - epoch_length_min) .* rand(input.PopulationSize,n_stim_events);
                
                InitialPopulationMatrix = [trial_types, onsets, durations];
            else
                InitialPopulationMatrix = [trial_types, onsets];
            end
            x = InitialPopulationMatrix;
            
%             options = optimoptions(@ga,'UseVectorized',false,...
%                 'PlotFcn',{@gaplotstopping,@gaplotbestf,@gaplotdistance},...
%                 'FunctionTolerance', 1e-6,...
%                 'EliteCount', input.EliteCount, ...'FitnessScalingFcn', @fitscalingshiftlinear,...
%                 'PopulationSize', input.PopulationSize,'InitialPopulationMatrix', InitialPopulationMatrix,...
%                 'UseParallel',false,...
%                 'MaxGenerations', 1e3, 'Display', 'diagnose');
            
%             [x, fval, exitflag, output, population, scores] = ...
%                 ga(f, n_vars,[],[],[],[],lb, ub, constraints,intcon,options); %#ok<ASGLU>
            exitflag = 1;
            if exitflag > 0
                % make model
                [stim_list, onsets, epoch_length] = ...
                    population_parser(x, n_stim_events, epoch_length_max);
                
                % warning suppressed because SPM is saved
                SPM = DconvMTX(stim_list, n_scan, n_stim_type, epoch_length, input.TR, onsets, input.dim_dur, dim_onsets); %#ok<NASGU>
                save(['sub-',num2str(sub, '%02d'), '_task-contrast_run-', num2str(run_to_save, '%02d'),...
                    '_side-', sides{side_to_save}, '_events_SPM.mat'],'SPM');
%                 save(['sub-', num2str(sub, '%02d'), '_task-contrast_run-', num2str(run_to_save, '%02d'),...
%                     '_side-', sides{side_to_save}, '_events_ga.mat'],'x','fval','output','population','scores');
                
                events = table();
                events.onset = onsets;
                events.duration = epoch_length;
                events.orientation = orientations(mod(stim_list, input.n_orientation)+1)';
                events.contrast = contrasts((stim_list < input.n_orientation) + 1)';
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
        data_dim.duration = repelem(input.dim_dur, n_dim_events)';
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

end

