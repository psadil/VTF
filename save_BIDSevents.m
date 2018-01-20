function save_BIDSevents(data, input, constants)

% need to grab actual phase end 
% write save directory
data.onset = data.tStart_realized - data.tStart_realized(1);
data.duration = data.tEnd_realized - data.tStart_realized;
switch input.experiment
    case 'contrast'
        events = data(:, ...
            {'onset','duration','orientation_left','contrast_left','orientation_right','contrast_right','trial','subject'});
        
        events = stack(stack(events,...
            {'orientation_left','orientation_right'},...
            'NewDataVariableName', 'orientation'),...
            {'contrast_left','contrast_right'},...
            'IndexVariableName', 'side',...
            'NewDataVariableName', 'contrast');
        side = cellfun(@(x) strsplit(x,'_'), cellstr(events.side), 'UniformOutput',false);
        events.side = cellfun(@(x) x(2), side);
        events.orientation_Indicator = [];
    case 'localizer'
        events = data(:, {'onset','duration'});
        events.trial_type = repelem({'checkerboard'}, size(events,1))';
end

filename = [fullfile(constants.func_dir, strjoin({['sub-',num2str(input.subject, '%02d')],...
    ['task-', input.experiment], ['run-', num2str(input.run, '%02d')], 'events'},'_')), '.tsv'];

writetable(events, filename,'FileType','text', 'Delimiter', 'tab');

end