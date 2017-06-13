function [ response, rt, firstCueOn, stimDown, vbl, missed, exitFlag ] = ...
    elicitContrastResp(firstFlipTime, window, responseHandler, stim,...
    keys, expParams, roboRT, answer, constants )

response = {[]};
rt = NaN;
stimDown = NaN;
vbl = NaN(stim.nFlipsPerTrial, 1);
missed = NaN(stim.nFlipsPerTrial, 1);
exitFlag = {'OK'};

%% draw initial cue

flipCount = 1;

waitTime = expParams.cueExpose;
flipCueAt = firstFlipTime;
[flipCount, vbl, missed, firstCueOn, exitFlag] = ...
    drawCueAndWait(flipCueAt, flipCount, vbl, missed, waitTime,...
    stim, window, responseHandler, constants, keys, exitFlag);
if strcmp(exitFlag, 'ESCAPE')
    return;
end


%% present first grating

acceptRest = false;
tex = stim.tex1;
expectedOnset = firstCueOn + expParams.cueExpose;
[flipCount, response, rt, vbl, missed, exitFlag] = ...
    presentStim(flipCount, vbl, missed, acceptRest, tex, expectedOnset, ...
    constants, keys, stim, window, responseHandler, roboRT, answer);
if strcmp(exitFlag, 'ESCAPE')
    return;
end


%% DELAY

waitTime = expParams.delay;
flipCueAt = vbl(flipCount);
[flipCount, vbl, missed, delayStart, exitFlag] = ...
    drawCueAndWait(flipCueAt, flipCount, vbl, missed, waitTime,...
    stim, window, responseHandler, constants, keys, exitFlag);
if strcmp(exitFlag, 'ESCAPE')
    return;
end


%% Second stimulus

acceptRest = true;
tex = stim.tex2;
expectedOnset = delayStart + expParams.delay;
[flipCount, response, rt, vbl, missed, exitFlag] = ...
    presentStim(flipCount, vbl, missed, acceptRest, tex, expectedOnset, ...
    constants, keys, stim, window, responseHandler, roboRT, answer);
if strcmp(exitFlag, 'ESCAPE')
    return;
end


%% soak up any remaining time

% final waiting duration is equal to however much of the trial duration
% didn't occur. This should keep the time tightly sync'ed to the scanner
waitTime = vbl(flipCount) - firstCueOn + expParams.trialDur;
[~, vbl, missed, stimDown, exitFlag] = ...
    drawCueAndWait(vbl(flipCount), flipCount, vbl, missed, waitTime,...
    stim, window, responseHandler, constants, keys, exitFlag);
if strcmp(exitFlag, 'ESCAPE')
    return;
end


end


function [flipCount, response, rt, vbl, missed, exitFlag] = ...
    presentStim(flipCount, vbl, missed, acceptResp, tex, expectedOnset, ...
    constants, keys, stim, window, responseHandler, roboRT, answer)

% create response cue after soaking up time because soaking up time
% utilizes its own cue (useful for pressing escape)
KbQueueCreate(constants.device, keys.resp + keys.escape);
for tick = 1:stim.nTicksPerStim
    
    if stim.flicker(tick)==1
        Screen('DrawTexture', window.pointer, tex, [], stim.srcRect, [], 1);
    end
    
    Screen('FillOval', window.pointer,p.fixColor, stim.fixRect); % MS color depends on trial type
    Screen('DrawingFinished', window.pointer);
    
    % as above, need to time the first flip based on the end of the delay
    % between gratings.
    if tick == 1
        [vbl(flipCount), ~, ~, missed(flipCount)] = ...
            Screen('Flip', window.pointer, ...
            (vbl(flipCount-1) + expectedOnset) + (1 - 0.5) * window.ifi);
        
        % record onset of when PTB tried to flip second stim
        stimUp = vbl(flipCount);
        
        % open up response cue
        KbQueueStart(constants.device);
    else
        [vbl(flipCount), ~, ~, missed(flipCount)] = ...
            Screen('Flip', window.pointer, ...
            vbl(flipCount-1) + (stim.nFlipsPerSecOfStim - 0.5) * window.ifi);
        
        % allow robot to respond if enough time has passed
        if (vbl(flipCount) - stimUp) > roboRT
            goRobo = 1;
        end
    end
    % always increment flipCount after each flip
    flipCount = flipCount + 1;
    
    if acceptResp
        [keys_pressed, press_times] =...
            responseHandler(constants.device, answer, goRobo);
        if ~isempty(keys_pressed)
            [response, rt, exitFlag] = ...
                wrapper_keyProcess(keys_pressed, press_times, stimUp, expt);
            % stop accepting responses after the first one given
            acceptResp = false;
            if strcmp(exitFlag, 'ESCAPE')
                return;
            end
        end
    end
    
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

end

function [flipCount, vbl, missed, cueOn, exitFlag] = ...
    drawCueAndWait(flipCueAt, flipCount, vbl, missed, waitTime, ...
    stim, window, responseHandler, constants, keys, exitFlag)

Screen('FillOval', window.pointer, stim.fixColor, stim.fixRect);
Screen('DrawingFinished', window.pointer);
[vbl(flipCount), ~, ~, missed(flipCount)] = ...
    Screen('Flip', window.pointer, ...
    flipCueAt + (1 - 0.5) * window.ifi);
cueOn = vbl(flipCount);
flipCount = flipCount + 1;

% soak up the remaining cue expose time, then move on
[~, ~, exitFlag] =...
    soakTime(keys.escape, cueOn, waitTime, ...
    [], NaN, exitFlag, responseHandler, constants);
if strcmp(exitFlag, 'ESCAPE')
    return;
end
end