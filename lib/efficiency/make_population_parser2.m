function population_parser = make_population_parser2(duration)

if duration
    population_parser = @wDuration;
else
    population_parser = @woDuration;
end

    function [stim_list, onsets, epoch_length] = wDuration(x, n_stim_events, varargin)

        stim_list = x(1:n_stim_events)';
        onsets = x(n_stim_events+1:n_stim_events*2)';
        epoch_length = x(2*n_stim_events+1:n_stim_events*3)';
  
    end

    function [stim_list, onsets, epoch_length] = woDuration(x, n_stim_events, epoch_length_max, scan_time, hrf_lag)

        stim_list = x(1:n_stim_events)';
        onsets = linspace(0,scan_time - epoch_length_max - hrf_lag, n_stim_events );
        epoch_length = repelem(epoch_length_max, n_stim_events)';
  
    end


end
