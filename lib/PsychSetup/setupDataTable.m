function data = setupDataTable( expParams, subject, experiment, constants )

switch experiment
    case 'contrast'
        n_trials_w_sides = expParams.nTrials*2;

        data = struct2table(tdfread(constants.ga_data, 'tab'));
        data = data(~strcmp(data.side,{'middle'}),:);
        data.orientation = str2double(data.orientation);
        data.contrast = str2double(data.contrast);
        
    case 'localizer'
        n_trials_w_sides = expParams.nTrials;
        
        data = table();
        data.onset = (0:expParams.iti:(expParams.scan_time-expParams.epoch_length))';
        data.duration = repelem(expParams.epoch_length, n_trials_w_sides)';
        data.subject = repelem(subject, n_trials_w_sides)';
        data.trial = (1:n_trials_w_sides)';
        if mod(subject,2)
            data.trial_type = repmat([{'checkerboard_left'};{'checkerboard_right'}], [n_trials_w_sides/2, 1]);
        else
            data.trial_type = repmat([{'checkerboard_right'};{'checkerboard_left'}], [n_trials_w_sides/2, 1]);            
        end
end

data.tEnd_expected_from0 = data.onset + data.duration;

data.tStart_realized = NaN([n_trials_w_sides,1]);
data.tEnd_realized = NaN([n_trials_w_sides,1]);

data.exitFlag = repmat({[]}, [n_trials_w_sides,1]);

data.luminance_difference = NaN([n_trials_w_sides,1]);
data.correct = NaN(n_trials_w_sides,1);

end
