function population_parser = make_population_parser3(~)

population_parser = @woDuration;

    function [stim_list, onsets, epoch_length] = woDuration(x, n_stim_events, epoch_length_max, resolution, n_dim_events)

        stim_list = [x(1:n_stim_events), 99]';
        iti = (x(1+n_stim_events : 2*n_stim_events-1) * resolution)';
        dim_iti = (x((2*n_stim_events) : end) * resolution)';
        
        % 0 contatinated to make addition nice (no iti before first stimulus)
        onsets = [(epoch_length_max * (0:(n_stim_events-1)))' + [0; cumsum(iti)];...
            (0.4 * (0:(n_dim_events-1)))' + [0; cumsum(dim_iti)] ];
        epoch_length = repelem(epoch_length_max, n_stim_events)';
  
    end


end