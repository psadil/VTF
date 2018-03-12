function population_parser = make_population_parser4(type)

switch type
    case 'dim'
        population_parser = @woDuration;
    case 'nodim'
        population_parser = @woDim;
        
end

    function [stim_list, onsets, epoch_length] = woDuration(x, n_stim_events,...
            epoch_length_max_flip, resolution, n_dim_events, trial_types, varargin)
        
        epoch_length_max = epoch_length_max_flip * resolution;
        stim_list = [trial_types, repelem(99,n_dim_events)]';
        iti = (x(1 : n_stim_events-1) * resolution)';
        dim_iti = (x((n_stim_events) : end) * resolution)';
        
        % 0 contatinated to make addition nice (no iti before first stimulus)
        onsets = [(epoch_length_max * (0:(n_stim_events-1)))' + [0; cumsum(iti)];...
            (0.4 * (0:(n_dim_events-1)))' + cumsum(dim_iti) ];
        epoch_length = repelem(epoch_length_max, n_stim_events)';
        
    end


    function [stim_list, onsets, epoch_length] = woDim(x, n_stim_events,...
            epoch_length_max_flip, resolution, n_dim_events, trial_types, dim_iti)
        
        epoch_length_max = epoch_length_max_flip * resolution;
        stim_list = [trial_types, repelem(99,n_dim_events)]';
        iti = (x(1 : n_stim_events-1) * resolution)';
        
        % 0 contatinated to make addition nice (no iti before first stimulus)
        onsets = [(epoch_length_max * (0:(n_stim_events-1)))' + [0; cumsum(iti)];...
            (0.4 * (0:(n_dim_events-1)))' + cumsum(dim_iti) ];
        epoch_length = repelem(epoch_length_max, n_stim_events)';
        
    end


end
