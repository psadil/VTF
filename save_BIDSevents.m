function save_BIDSevents(data, input, constants, dimming_data)

% need to grab actual phase end
% write save directory
data.onset_realized = data.tStart_realized - data.tStart_realized(1);
data.duration_realized = data.tEnd_realized - data.tStart_realized;

dimming_data.onset_realized = dimming_data.tStart_realized - dimming_data.tStart_realized(1);
dimming_data.duration_realized = dimming_data.tEnd_realized - dimming_data.tStart_realized;

events_dim = dimming_data(:, {'onset_realized','duration_realized','trial','subject','rt_given'});
events_dim.rt_given = strtrim(cellstr(num2str(events_dim.rt_given)));
missed_dims = strcmp(events_dim.rt_given,{'NaN'});
events_dim.rt_given(missed_dims) = repelem({'n/a'}, sum(missed_dims))';
switch input.experiment
    case 'contrast'
        events_main = data(:, ...
            {'onset_realized','duration_realized',...
            'orientation','contrast','side', 'trial','subject'});  
        events_main.orientation = strtrim(cellstr(num2str(events_main.orientation)));
        events_main.contrast = strtrim(cellstr(num2str(events_main.contrast)));
        events_main.side = strtrim(cellstr(num2str(events_main.side)));
        
        events_dim.orientation = repelem({'n/a'}, size(events_dim,1))';
        events_dim.contrast = repelem({'n/a'}, size(events_dim,1))';
        events_dim.side = repelem({'middle'}, size(events_dim,1))';
        
    case 'localizer'
        events_main = data(:, {'onset_realized','duration_realized','trial','subject'});
        events_main.trial_type = repelem({'checkerboard'}, size(events_main,1))';
        
        events_dim.trial_type = repelem({'dim'}, size(events_dim,1))';
        
end

events_main.rt_given = repelem({'n/a'}, size(events_main,1))';
events = [events_main; events_dim];

events.Properties.VariableNames{'onset_realized'} = 'onset';
events.Properties.VariableNames{'duration_realized'} = 'duration';
events.Properties.VariableNames{'rt_given'} = 'response_time';
events = sortrows(events, 'onset');

filename = [fullfile(constants.func_dir, strjoin({['sub-',num2str(input.subject, '%02d')],...
    ['task-', input.experiment], ['run-', num2str(input.run, '%02d')], 'events'},'_')), '.tsv'];

writetable(events, filename,'FileType','text', 'Delimiter', 'tab');

end