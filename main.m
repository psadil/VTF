function  main(varargin)

% warning from inputemu

%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
addParameter(ip, 'subject', 1, @isnumeric);
addParameter(ip, 'responder', 'user', @(x) sum(strcmp(x, {'user','simpleKeypressRobot','setup'}))==1);
addParameter(ip, 'refreshRate', 120, @(x) x == 120 | x == 60);
addParameter(ip, 'run', 0, @isnumeric);
addParameter(ip, 'fMRI', true, @islogical);
addParameter(ip, 'debugLevel', 0, @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'experiment', 'contrast',  @(x) sum(strcmp(x, {'contrast','localizer'}))==1);
addParameter(ip, 'delta_luminance_guess', 0.3,  @isnumeric);
addParameter(ip, 'TR', 1.5,  @isnumeric);
addParameter(ip, 'sigma_scale', 1.5, @isnumeric); % by how much to scale sigma value
addParameter(ip, 'tracker', 'none', @(x) sum(strcmp(x, {'T60', 'none'}))==1);
addParameter(ip, 'dummymode', false, @(x) @islogical);
addParameter(ip, 'give_feedback', false, @islogical);
addParameter(ip, 'scan', false, @isnumeric); % used to id eyetracking data
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
% if ~input.fMRI && input.run == 0 && strcmp(input.responder,'user') && input.debugLevel == 0
%     demographics(constants.subDir);
% end

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
%             acc = checkAccuracy(data);
            expt = input.experiment;
            subject = input.subject;
            run = input.run;
            structureCleanup(expt, subject, run, data, constants, tInfo, expParams, stairs, stim, dimming_data, el);
            save_BIDSevents(data, input, constants, dimming_data);
            
%             showPrompt(window, sprintf('You were %.0f%% correct', acc*100), 0);
%             WaitSecs(3);
    end
    
    
    switch input.tracker
        case 'none'
        case 'T90'
            %  the Eyelink('ReceiveFile') function does not wait for the file
            % transfer to complete so you must have the entire try loop
            % surrounding the function to ensure complete transfer of the EDF.
            try
                fprintf('Receiving data file ''%s''\n',  constants.eyelink_data_fname );
                status = eyetrackerFcn('ReceiveFile');
                if status > 0
                    fprintf('ReceiveFile status %d\n', status);
                end
                if 2==exist(edfFile, 'file')
                    fprintf('Data file ''%s'' can be found in ''%s''\n',  constants.eyelink_data_fname, pwd );
                end
            catch
                fprintf('Problem receiving data file ''%s''\n',  constants.eyelink_data_fname );
            end
    end
    
    windowCleanup(constants, eyetrackerFcn, fb);
    
catch msg
    windowCleanup(constants, eyetrackerFcn, fb);
    rethrow(msg)
end


return