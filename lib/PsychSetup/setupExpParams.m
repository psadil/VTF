function expParams = setupExpParams( debugLevel, fMRI )
%setupDebug setup values specific to debug levels


%% Defaults regardless of fMRI or debug level
expParams.screen_scale = []; % show at full screen

% stimulus timing stuff
expParams.cueExpose = .2;

% stimulus duration in seconds
expParams.stimDur = 2;

% MS delay between sample & test (secs)
expParams.delay = .4;

% MS test duration (secs)
expParams.testDur = 2;

% temporal window for a resp to be counted as correct, seconds:
% effectively serves as an ITI as well
expParams.respWin = 2;

% number of orientations to test
expParams.numOrients = 9;

%% Set general parameters that change based on debug level only
switch debugLevel
    case 0
        expParams.iti = 1; % seconds to wait between each trial
        % nTrials=36 : 9 orientations, 2 samples per scan, two trial types
        expParams.nExpTrials = 36;
        % number of null 'fixation trials'
        expParams.nNulls = 8;
        
    case 1
        expParams.iti = .1;
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
% freqSeq determines flicker of stim
%p.cueExpose = round(p.cueExpose/p.ifi);
expParams.stimDur = round(expParams.stimDur/window.ifi);
expParams.delay = round(expParams.delay/window.ifi);
expParams.testDur = round(expParams.testDur/window.ifi);
expParams.maxTrialFrames = expParams.cueExpose + expParams.stimDur + expParams.delay + expParams.testDur;



% total duration of trial
expParams.trialDur = ...
    expParams.cueExpose + expParams.stimDur + expParams.delay + ...
    expParams.testDur + expParams.respWin;

% total number of trials, including all types
expParams.nTrials = expParams.nExpTrials + expParams.nNulls;

% expected duration of scan
expParams.scanDur_expected = ...
    expParams.postDur + (expParams.trialDur*expParams.nTotalTrials);

end
