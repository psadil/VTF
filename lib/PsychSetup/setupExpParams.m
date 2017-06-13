function expParams = setupExpParams( debugLevel, fMRI, experiment )



%% Defaults regardless of fMRI or debug level
expParams.screen_scale = []; % show at full screen

switch experiment
    case 'contrast'
        % stimulus timing stuff
        expParams.cueExpose = .2;
        
        % stimulus duration in seconds
        expParams.stimDur = 2;
        
        % delay between sample & test (secs)
        expParams.delay = .4;
        
        % test duration (secs)
        expParams.testDur = 2;
        
        % temporal window for a resp to be counted as correct, seconds
        % effectively serves as an ITI as well
        expParams.respWin = 2;
        
        % number of orientations to test
        expParams.numOrients = 9;
        
        %% Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % nTrials=36 : 9 orientations, 2 samples per scan, two trial types
                expParams.nExpTrials = 36;
                % number of null 'fixation trials'
                expParams.nNulls = 8;
                
            case 1
                expParams.nExpTrials = 8;
                % number of null 'fixation trials'
                expParams.nNulls = 2;
        end
        
        switch fMRI
            case true
                expParams.nNulls = 8;
                expParams.postDur = 9;  % changed to 9 to make total time nice
            case false
                expParams.nNulls = 0;
                expParams.postDur = 0;
        end
        
        %% defaults that need calculating
        
        %--------------------------------------------------------------------------
        % Generate time sequence for a trial.
        expParams.totalStimDur = expParams.cueExpose + expParams.stimDur + expParams.delay + expParams.testDur;
        
        % total duration of trial
        expParams.trialDur = ...
            expParams.cueExpose + expParams.stimDur + expParams.delay + ...
            expParams.testDur + expParams.respWin;
        
        % total number of trials, including all types
        expParams.nTrials = expParams.nExpTrials + expParams.nNulls;
        
        
    case 'localizer'
        
        % stimulus duration in seconds
        expParams.stimDur = 10;
        
        % time between stimulus presentations in seconds
        expParams.iti = 10;
        
        % numer of times that stimulus will dim within a trial
        expParams.nTimesDim = 5;
        
        expParams.trialDur = expParams.stimDur + expParams.iti;
        
        % -----------------------------------------------------------------
        % Set general parameters that change based on debug level only
        switch debugLevel
            case 0
                % total number of trials
                expParams.nTrials = 15;
                
            case 1
                expParams.nTrials = 3;
        end
        
        % -----------------------------------------------------------------
        % Set general parameters that change based on whether in or out of
        % scanner
        switch fMRI
            case true
                expParams.postDur = 9;  % changed to 9 to make total time nice
            case false
                expParams.postDur = 0;
        end
        
        
end

% expected duration of scan
expParams.scanDur_expected = ...
    expParams.postDur + (expParams.trialDur*expParams.nTrials);

end
