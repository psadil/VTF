function expParams = setupExpParams( debugLevel, experiment, constants )


%% Defaults regardless of fMRI or debug level
expParams.screen_scale = []; % show at full screen

% duration of fixation dimming
expParams.fix_dim_dur_sec = 0.4;

switch experiment
    case 'contrast'
        
        expParams.scan_time = 420;
        
        data = struct2table(tdfread(constants.ga_data, 'tab'));
        data = data(~strcmp(data.side,{'middle'}),:);
                        
        % number of orientations to test
        % 2 unique orientations on each trial in each run
        expParams.nOrientations = length(unique(data.orientation));
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = length(unique(data.contrast));
                
        expParams.nTrials = size(data,1)/2;
                
    case 'localizer'
        
        expParams.scan_time = 320;
        
        % stimulus duration in seconds
        expParams.epoch_length = 16;
        expParams.iti = 16;
                
        % just horizontal and vertical
        expParams.nOrientations = 2;
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = 1;
                
        % -----------------------------------------------------------------
        % total number of trials
        expParams.reps = 20;

        % multiplication by
        expParams.nTrials = expParams.reps;
end

end
