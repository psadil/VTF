function  main(varargin)

% warning from inputemu
warning('off', 'MATLAB:nargchk:deprecated');

%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
addParameter(ip, 'subject', 1, @isnumeric);
addParameter(ip, 'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot','setup'}))==1);
addParameter(ip, 'refreshRate', 60, @(x) x==60);
addParameter(ip, 'run', 0, @isnumeric);
addParameter(ip, 'fMRI', true, @islogical);
addParameter(ip, 'debugLevel', 0, @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'experiment', 'contrast',  @(x) sum(strcmp(x, {'contrast','localizer'}))==1);
addParameter(ip, 'delta_luminance_guess', 0.3,  @isnumeric);
addParameter(ip, 'TR', 1.5,  @isnumeric);
addParameter(ip, 'sigma_scale', 1, @isnumeric); % by how much to scale sigma value
addParameter(ip, 'tracker', 'none', @(x) sum(strcmp(x, {'T60', 'none'}))==1);
addParameter(ip, 'dummymode', false, @(x) @islogical);
addParameter(ip, 'give_feedback', true, @islogical);
parse(ip,varargin{:});
input = ip.Results;


% setup folders (add everything to path)
[constants, input, exit_stat] = setupConstants(input, ip);

eyetrackerFcn = makeEyelinkFcn(input.tracker);
fb = setupFeedback();

if exit_stat==1
    windowCleanup(constants, eyetrackerFcn, fb);
    return
end

% gather demographics for practice run
if ~input.fMRI && input.run == 0 && strcmp(input.responder,'user') && input.debugLevel == 0
    demographics(constants.subDir);
end

%% run main experiment
% try to fail gracefully (meaning automatically restore keyboard)
try
    PsychDefaultSetup(2);
    ListenChar(-1);
    HideCursor;
    
    responseHandler = makeInputHandlerFcn(input.responder);
    window = setupWindow(constants, input);
    
    % main experiment function
    [data, tInfo, expParams, stairs, stim, dimming_data, el] = ...
        runContrast(input, constants, window, responseHandler, eyetrackerFcn, fb);
    
    % save data
    switch input.responder
        case {'user', 'simpleKeypressRobot'}
            acc = checkAccuracy(data);
            expt = input.experiment;
            subject = input.subject;
            run = input.run;
            structureCleanup(expt, subject, run, data, constants, tInfo, expParams, stairs, stim, dimming_data, el);
            save_BIDSevents(data, input, constants, dimming_data);
            
            % NOTE: correct is for both finding and refraining from pressing
%             showPrompt(window, sprintf('You were %.0f%% correct', acc*100), 0);
%             WaitSecs(3);
    end
    
    fprintf('Receiving data file ''%s''\n', constants.eye_data );
    eyetrackerFcn('ReceiveFile',[],[],constants.savePath);
    
    windowCleanup(constants, eyetrackerFcn, fb);
    
catch msg
    windowCleanup(constants, eyetrackerFcn, fb);
    rethrow(msg)
end


return