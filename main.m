function acc = main(varargin)


%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
%#ok<*NVREPL> dont warn about addParamValue
addParamValue(ip, 'subInitials', 'PS', @isnumeric);
addParamValue(ip, 'subject', 0, @isnumeric);
addParamValue(ip, 'sessNumb', 1, @isnumeric);
addParamValue(ip, 'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot'}))==1);
addParamValue(ip, 'refreshRate', 120, @(x) x==120);
addParamValue(ip, 'runNumber', 1, @isnumeric);
addParamValue(ip, 'fMRI', true, @isLogical);
addParamValue(ip, 'contrastChange', [.08, .08], @isLogical);
addParamValue(ip, 'debugLevel', 0, @(x) isnumeric(x) && x >= 0);
parse(ip,varargin{:});
input = ip.Results;

%200 TRs @ 1.5s/TR
%150 TRs @ 2s/TR

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
[data, tInfo, expParams, input, qp, stim] = ...
    runContrast(input, constants, window, responseHandler);
acc = checkAccuracy(data);

% save data
expt = 'contrast';
structureCleanup(expt, input.subject, data, constants, tInfo, expParams, qp, stim);

windowCleanup(constants);



return