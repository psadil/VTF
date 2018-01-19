function  main(varargin)

% warning from inputemu
warning('off', 'MATLAB:nargchk:deprecated');

%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
addParameter(ip, 'subject', 0, @isnumeric);
addParameter(ip, 'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot'}))==1);
addParameter(ip, 'refreshRate', 60, @(x) x==60);
addParameter(ip, 'run', 0, @isnumeric);
addParameter(ip, 'fMRI', false, @islogical);
addParameter(ip, 'debugLevel', 0, @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'experiment', 'contrast',  @(x) sum(strcmp(x, {'contrast','localizer'}))==1);
addParameter(ip, 'delta_luminance_guess', 0.3,  @isnumeric);
addParameter(ip, 'TR', 1.5,  @isnumeric);
parse(ip,varargin{:});
input = ip.Results;

% setup folders (add everything to path)
[constants, input, exit_stat] = setupConstants(input, ip);
if exit_stat==1
    windowCleanup(constants);
    return
end

% gather demographics for practice run
if ~input.fMRI && input.run == 1
    demographics(constants.subDir);
end

%% run main experiment
% try to fail gracefully (meaning automatically restore keyboard)
try    
    PsychDefaultSetup(2);
    ListenChar(-1);

    responseHandler = makeInputHandlerFcn(input.responder);
    window = setupWindow(constants, input);
    
    % main experiment function
    [data, tInfo, expParams, stairs, stim] = ...
        runContrast(input, constants, window, responseHandler);
    acc = checkAccuracy(data);
    
    % save data
    expt = input.experiment;
    subject = input.subject;
    run = input.run;
    structureCleanup(expt, subject, run, data, constants, tInfo, expParams, stairs, stim);
    save_BIDSevents(data, input, constants);
    
    % NOTE: correct is for both finding and refraining from pressing
    showPrompt(window, sprintf('You were %.0f%% correct', acc*100), 0);
    WaitSecs(3);
    windowCleanup(constants);
    
catch msg
    windowCleanup(constants);
    rethrow(msg)
end


return