function design_constraints = make_design_constraints(duration)

if duration
    design_constraints = @wDuration;
else
    design_constraints = @woDuration;
end

    function [c, ceq] = wDuration(x, min_onset_diff, n_stim_events, epoch_length_max, population_parser)
        % Problem parameters
        % - minimum allowable difference between onsets
        
        % design parameters
%         onsets = x(n_stim_events+1:n_stim_events*2);
%         epoch_length = x(2*n_stim_events+1:n_stim_events*3);
        [~, onsets, epoch_length] = ...
            population_parser(x, n_stim_events, epoch_length_max, 420, 12);
        
        % calculate constraints
        stim_onset_contraints = -1*(diff(onsets) - epoch_length(1:end-1) - min_onset_diff);
        
        %
        c = stim_onset_contraints';
        
        % No equality constraints
        ceq = [];
    end

    function [c, ceq] = woDuration(x, min_onset_diff, n_stim_events, epoch_length_max, population_parser)
        % Problem parameters
        % - minimum allowable difference between onsets
        
        % design parameters
        %         onsets = x(n_stim_events+1:n_stim_events*2);
        %         epoch_length = repelem(max_onset_diff, n_stim_events);
        
        [~, onsets, epoch_length] = ...
            population_parser(x, n_stim_events, epoch_length_max, 420, 12);
        
        % calculate constraints
        stim_onset_contraints = -1*(diff(onsets) - epoch_length(1:end-1) - min_onset_diff);
        
        %
        c = stim_onset_contraints';
        
        % No equality constraints
        ceq = [];
    end

end
