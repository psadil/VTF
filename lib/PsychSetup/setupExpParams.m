function expParams = setupExpParams( debugLevel, fMRI, experiment )



%% Defaults regardless of fMRI or debug level
expParams.screen_scale = []; % show at full screen

switch experiment
    case 'contrast'
        
        % stimulus duration in seconds
        expParams.trial_stim_dur_sec = 5.2;
        
        % duration of fixation dimming
        expParams.fix_dim_dur_sec = 0.4;
        
        % range allowed between dimming events
        expParams.fix_dim_interval_range_sec = [0.6, 1];
        
        % number of dims per trial
        expParams.n_fix_dims = 2;
        
        % number of phases to store within a trial (dim + not dimmed)
        expParams.nPhasePerTrial = expParams.n_fix_dims*2 + 1;
        
        % temporal window for a resp to be counted as correct, seconds
        % effectively serves as an ITI as well
        expParams.iti_dur_sec = 3.8;
        
        % number of orientations to test
        % 2 unique orientations on each trial in each run
        expParams.nOrientations = 9;
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = 2;
        
        %% Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % number of contrast:orientation reps
                expParams.reps = 3;
            case 1
                expParams.reps = 1;
        end
        
        
        %% defaults that need calculating
        
        % multiplication by
        expParams.nTrials = expParams.reps * expParams.nOrientations * expParams.nContrasts;
        
        % phasesInRun := rows of grand data table
        expParams.nPhasesInRun = expParams.nTrials * expParams.nPhasePerTrial;
        
        %--------------------------------------------------------------------------
        % total duration of trial
        expParams.trial_total_dur = ...
            expParams.trial_stim_dur_sec + expParams.iti_dur_sec;
        
    case 'localizer'
        
        % stimulus duration in seconds
        expParams.stimDur = 10;
        
        % time between stimulus presentations in seconds
        expParams.iti = 10;
        
        % numer of times that stimulus will dim within a trial (targets)
        expParams.nTimesDim = 5;
        
        expParams.trialDur = expParams.stimDur + expParams.iti;
        
        % number of frames to present target
        expParams.targDurSecs = .4;
        
        % seconds in which a response can be made
        expParams.respWindowSecs = 1;
        
        % contrast of target stimulus
        expParams.targetContrast = .3;
        
        % -----------------------------------------------------------------
        % Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % total number of trials
                expParams.nTrials = 15;
                
            case 1
                expParams.nTrials = 3;
        end
        
end

% -----------------------------------------------------------------
% Set general parameters that change based on whether in or out of
% scanner
switch fMRI
    case true
        % with fMRI, want a bit of extra time at end to allow for
        % HRF to relax on final trial
        expParams.post_dur = 9;
    case false
        expParams.post_dur = 0;
end


% expected duration of scan
expParams.scan_dur_expected = ...
    expParams.post_dur + (expParams.trial_total_dur*expParams.nTrials);

end
