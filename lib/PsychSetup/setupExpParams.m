function expParams = setupExpParams( debugLevel, experiment )


load('D:\git\fMRI\VTF\lib\efficiency\model1_1-18-2018.mat');

%% Defaults regardless of fMRI or debug level
expParams.screen_scale = []; % show at full screen

% duration of fixation dimming
expParams.fix_dim_dur_sec = 0.4;

% range allowed between dimming events
expParams.fix_dim_interval_sec = 0.8;

switch experiment
    case 'contrast'
        
        % stimulus duration in seconds
        expParams.isi = M.ga.ISI;
                
        % number of orientations to test
        % 2 unique orientations on each trial in each run
        expParams.nOrientations = 9;
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = 2;
                
        expParams.nTrials = M.ga.scanLength / M.ga.ISI;
        
        % related to expParams.fix_dim_interval_sec and M.ga.ISI
        expParams.maxPhasePerTrial = 5+ceil(expParams.isi / (expParams.fix_dim_interval_sec + expParams.fix_dim_dur_sec ) );
        
    case 'localizer'
        
        % stimulus duration in seconds
        expParams.isi = 16;
                
        % just horizontal and vertical
        expParams.nOrientations = 2;
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = 1;
        
        % related to expParams.fix_dim_interval_sec and M.ga.ISI
        expParams.maxPhasePerTrial = 10 + ceil(expParams.isi / (expParams.fix_dim_interval_sec + expParams.fix_dim_dur_sec ) );
        
        % -----------------------------------------------------------------
        % Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % total number of trials
                expParams.reps = 10;
                
            otherwise
                expParams.reps = 3;
        end

        % multiplication by
        expParams.nTrials = expParams.reps * expParams.nOrientations * expParams.nContrasts;
end
expParams.scan_length_expected = M.ga.scanLength;

expParams.maxPhasesPerRun = expParams.maxPhasePerTrial * expParams.nTrials;

end
