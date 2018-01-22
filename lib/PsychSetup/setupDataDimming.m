function dimming_data = setupDataDimming( expParams, keys, data, constants, experiment, responder, subject )

dim_dur = 0.4;

switch experiment
    
    case 'contrast'
        dimming_data = struct2table(tdfread(constants.ga_data, 'tab'));
        dimming_data = dimming_data(strcmp(dimming_data.side,{'middle'}),:);
        dimming_data.orientation = [];
        dimming_data.contrast = [];
        
        n_dim_events = size(dimming_data,1);
        
    case 'localizer'
        
        switch responder
            
            case 'setup'
                dim_sep_max = 4;
                dim_sep_min = 3;
                
                n_dim_events = floor(expParams.scan_time / (dim_dur + dim_sep_max));
                dim_diffs = dim_sep_min + (dim_sep_max - dim_sep_min)*rand([n_dim_events,1]);
                dim_onsets = cumsum(dim_diffs)' + (dim_dur*(0:n_dim_events-1));
                
                dimming_data = table();
                dimming_data.onset = dim_onsets';
                dimming_data.duration = repelem(dim_dur, n_dim_events)';
                dimming_data.trial = (1:n_dim_events)';
                
                writetable(dimming_data, constants.dimming_data, 'Filetype', 'text', 'Delimiter', 'tab');
            otherwise
                dimming_data = struct2table(tdfread(constants.dimming_data, 'tab'));
                n_dim_events = size(dimming_data,1);
        end
end
dimming_data.subject = repelem(subject, n_dim_events)';

dimming_data.trial_exp = NaN([n_dim_events,1]);
for trial = 1:expParams.nTrials
    for dim = 1:n_dim_events
        if all(dimming_data.onset(dim) >= data.onset(data.trial==trial) ) && ...
                ( any(dimming_data.onset(dim) < data.onset(data.trial==(trial+1)) ) || ...
                trial == expParams.nTrials )
            
            dimming_data.trial_exp(dim) = trial;
        end
    end
end


dimming_data.tEnd_expected_from0 = dimming_data.onset + dim_dur;

dimming_data.tStart_realized = NaN([n_dim_events,1]);
dimming_data.tEnd_realized = NaN([n_dim_events,1]);


dimming_data.answer = repelem({KbName(keys.resp)}, n_dim_events)';

dimming_data.roboResponse_expected = repelem({keys.robo_resp}, n_dim_events)';
dimming_data.roboRT_expected = repelem(0.2, n_dim_events)';

dimming_data.rt_given = NaN([n_dim_events,1]);
dimming_data.response_given = repmat({[]}, [n_dim_events,1]);

end
