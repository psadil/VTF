function acc = main(varargin)
acc = NaN;

%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip, 'subject', 0, @isnumeric);
addParamValue(ip, 'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot'}))==1);
addParamValue(ip, 'refreshRate', 60, @(x) x==60);
addParamValue(ip, 'run', 1, @isnumeric);
addParamValue(ip, 'fMRI', false, @islogical);
addParamValue(ip, 'debugLevel', 0, @(x) isnumeric(x) && x >= 0);
addParamValue(ip, 'experiment', 'contrast',  @(x) sum(strcmp(x, {'contrast','localizer'}))==1);
addParamValue(ip, 'delta_luminance_guess', 0.3,  @isnumeric);
parse(ip,varargin{:});
input = ip.Results;

%% setup
[constants, input, exit_stat] = setupConstants(input, ip);
if exit_stat==1
    windowCleanup(constants);
    return
end
if input.fMRI && input.runNumber == 1
    demographics(constants.subDir);
end


PsychDefaultSetup(2);
ListenChar(-1);
responseHandler = makeInputHandlerFcn(input.responder);

% monitor stuff
window = setupWindow(constants, input);


%% run main experiment

switch input.experiment
    case 'contrast'
        [data, tInfo, expParams, stairs, stim] = ...
            runContrast(input, constants, window, responseHandler);
        acc = checkAccuracy(data);
    case 'localizer'
        [data, tInfo, expParams, input, stairs, stim] = ...
            runLocalizer(input, constants, window, responseHandler);
        acc = checkAccuracy(data);
end

% save data
expt = input.experiment;
subject = input.subject;
run = input.run;
structureCleanup(expt, subject, run, data, constants, tInfo, expParams, stairs, stim);

% NOTE: correct is for both finding and refraining from pressing
showPrompt(window, sprintf('You were %.0f%% correct', acc*100), 0);
WaitSecs(3);
windowCleanup(constants);

return