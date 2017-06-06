function [ response, rt, stimOn, stimDown, vbl, missed, exitFlag ] =...
    elicitContrastResp( window, responseHandler, stim,...
    keys, expParams, roboRT, answer, constants )

response = {[]};
rt = NaN;
stimDown = NaN;
vbl = NaN(expParams.trialFlips,1);
missed = NaN(expParams.trialFlips,1);
exitFlag = {'OK'};

flipCount = 1;

%% draw initial cue
Screen('FillOval', window.pointer, stim.fixColor, stim.fixRect);
Screen('DrawingFinished', window.pointer);
[vbl(flipCount), ~, ~, missed(flipCount)] = Screen('Flip', window.pointer);
stimOn = vbl(1);

% soak up the remaining cue expose time, then move on
[~, ~, exitFlag] =...
    soakTime(keys.escape, stimOn, expParams.cueExpose, ...
    [], NaN, exitFlag, responseHandler, constants);
if strcmp(exitFlag, 'ESCAPE')
    return;
end


%% present each grating

% put up the first interval
for i = 1:expParams.stimDur
    flipCount = flipCount + 1;
    
    if p.flicker(i)==1
        Screen('DrawTexture', window.pointer, stim1, [], srcRect, [], 1);
    end
    
    Screen('FillOval', window.pointer, stim.fixColor, stim.fixRect); % MS color depends on trial type
    Screen('DrawingFinished', window.pointer);
    [vbl(flipCount), ~, ~, missed(flipCount)] = ...
        Screen('Flip', window.pointer);
end

%DELAY
flipCount = flipCount + 1;
Screen('FillOval', window.pointer, stim.fixColor, stim.fixRect);
Screen('DrawingFinished', window.pointer);
[vbl(flipCount), ~, ~, missed(flipCount)] = ...
    Screen('Flip', window.pointer);

[~, ~, exitFlag] =...
    soakTime(keys.escape, vbl(flipCount), expParams.delaySecs, ...
    [], NaN, exitFlag, responseHandler, constants);
if strcmp(exitFlag, 'ESCAPE')
    return;
end

KbQueueCreate(constants.device, keys.resp + keys.escape);
%Second interval
for i = 1:p.stimDur
    flipCount = flipCount + 1;
    
    if p.flicker(i)==1
        Screen('DrawTexture', window.pointer,stim2, [], srcRect, [], 1);
    end
    
    Screen('FillOval', window.pointer,p.fixColor, fixRect); % MS color depends on trial type
    Screen('DrawingFinished', window.pointer);
    [vbl(flipCount), ~, ~, missed(flipCount)] = ...
        Screen('Flip', window.pointer);
    
    if i == 1
        stim2up = vbl;
        KbQueueStart(constants.device);
    end
    if (vbl(flipCount) - stim2up) > roboRT
        goRobo = 1;
    end
    
    [keys_pressed, press_times] = responseHandler(constants.device, answer, goRobo);
    if ~isempty(keys_pressed)
        [response, rt, exitFlag] = ...
            wrapper_keyProcess(keys_pressed, press_times, stim2up, expt);
    end
    
end
Screen('FillOval', window.pointer, stim.fixColor, stim.fixRect);
Screen('DrawingFinished', window.pointer);
[vbl(flipCount), ~, ~, missed(flipCount)] = ...
    Screen('Flip', window.pointer);
stimDown = vbl(flipCount);

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);


[response, rt, exitFlag] = ...
    soakTime(keys.escape + keys.resp, stim2up, expParams.trialDur, ...
    response, rt, exitFlag, responseHandler, constants);


end

