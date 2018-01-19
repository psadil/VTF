function expParams = setupExpParams( debugLevel, fMRI, experiment, TR )



%% Defaults regardless of fMRI or debug level
expParams.screen_scale = []; % show at full screen

% duration of fixation dimming
expParams.fix_dim_dur_sec = 0.4;

% range allowed between dimming events
expParams.fix_dim_interval_range_sec = [0.6, 1];

switch experiment
    case 'contrast'
        
        % stimulus duration in seconds
        expParams.trial_stim_dur_sec = 5.2;
        
        % temporal window for a resp to be counted as correct, seconds
        % effectively serves as an ITI as well
        expParams.iti_dur_sec = 3.8;
        
        % number of orientations to test
        % 2 unique orientations on each trial in each run
        expParams.nOrientations = 9;
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = 2;
        
        % number of dims per trial
        expParams.n_fix_dims = 2;

        
        %% Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % number of contrast:orientation reps
                expParams.reps = 3;
            case 1
                expParams.reps = 1;
        end
        
        
    case 'localizer'
        
        % stimulus duration in seconds
        expParams.trial_stim_dur_sec = 16;
        
        % time between stimulus presentations in seconds
        expParams.iti_dur_sec = 16;
        
        % just horizontal and vertical
        expParams.nOrientations = 2;
        
        % number of contrast levels at which to present each orientation in
        % a run
        expParams.nContrasts = 1;
        
        % number of dims per trial (only 2 currently works)
        expParams.n_fix_dims = 2;
        
        % -----------------------------------------------------------------
        % Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % total number of trials
                expParams.reps = 10;
                
            otherwise
                expParams.reps = 3;
        end
        
end

%% defaults that need calculating

% number of phases to store within a trial (dim + not dimmed)
expParams.nPhasePerTrial = expParams.n_fix_dims*2 + 1;

% multiplication by
expParams.nTrials = expParams.reps * expParams.nOrientations * expParams.nContrasts;

% phasesInRun := rows of grand data table
expParams.nPhasesInRun = expParams.nTrials * expParams.nPhasePerTrial;

%--------------------------------------------------------------------------
% total duration of trial
expParams.trial_total_dur = ...
    expParams.trial_stim_dur_sec + expParams.iti_dur_sec;

% -----------------------------------------------------------------
% Set general parameters that change based on whether in or out of
% scanner
switch fMRI
    case true
        % with fMRI, want a bit of extra time at end to allow for
        % HRF to relax on final trial
        expParams.post_dur = 10;
    case false
        expParams.post_dur = 0;
end

% expected duration of scan
expParams.scan_dur_expected = ...
    expParams.post_dur + (expParams.trial_total_dur*expParams.nTrials)*TR;

end
