function [ response, rt, vbl, missed, exitFlag, tStart, phaseStart ] = ...
    elicitContrastResp(firstFlipTime, window, responseHandler, stim,...
    keys, expParams, roboRT, roboResp, constants, phases, angles, dim_sequence, luminance, contrasts )

%{
    Each trial has 5 phases. Trials begin and end with fixation presented
    at regular luminance. The fixation dims twice during this period.
    Participants are tasked to indicate when the dimming occurs. There is a
    brief duration between the two dimming periods during which the regular
    fixation cross is present. Hence, there are 5 phases during which
    participants could provide a response
    
    % Makes use of ProceduralGabor, a typical invocation to draw a single gabor patch may look like this:
%
% Screen('DrawTexture', windowPtr, gaborid, [], dstRect, Angle, [], [],
% modulateColor, [], kPsychDontDoRotation, [phase+180, freq, sc,
% contrast, aspectratio, 0, 0, 0]);
    
    %}
    
    % default return parameters
    response = repelem({'NO RESPONSE'},expParams.nPhasePerTrial)';
    rt = NaN([expParams.nPhasePerTrial,1]);
    vbl = NaN(stim.nFlipsPerTrial, 1);
    missed = NaN(stim.nFlipsPerTrial, 1);
    exitFlag = repelem({'OK'}, expParams.nPhasePerTrial)';
    tStart = NaN(expParams.nPhasePerTrial,1);
    phaseStart = NaN(expParams.nPhasePerTrial,1);
    
    % gabor parameters that are constant through trial
    
    %% start flipping stims
    phase = 1;
    KbQueueCreate(constants.device, keys.resp + keys.escape);
    for flip = 1:stim.nFlipsPerTrial
        
        % Batch-Draw all gratings 
        Screen('DrawTextures', window.pointer, stim.tex, [],...
            stim.dstRects, angles, [], [], [], [], [], ...
            [phases(flip,:); repelem(stim.grating_freq_cpp,2);...
            contrasts; zeros(1,2)]);
        
        % always draw central fixation cross
        drawFixation(window, stim.fixRect, stim.fixLineSize, luminance(dim_sequence(flip)+1));
        
        Screen('DrawingFinished', window.pointer);
        
        if flip == 1
            [vbl(flip), ~, ~, missed(flip)] = ...
                Screen('Flip', window.pointer, ...
                firstFlipTime + (1 - 0.5) * window.ifi);
            tStart(1:expParams.nPhasePerTrial) = vbl(flip);
            phaseStart(1) = vbl(flip);

            % open up response cue and allow response
            KbQueueStart(constants.device);
            goRobo = 0;
        else
            [vbl(flip), ~, ~, missed(flip)] = ...
                Screen('Flip', window.pointer, ...
                vbl(flip-1) + ((1/stim.update_phase_sec) - 0.5) * window.ifi);
            
            % allow robot to respond if enough time has passed
            if (vbl(flip) - vbl(1)) > roboRT
                goRobo = 1;
            end
            if dim_sequence(flip) ~= dim_sequence(flip-1)
                phase = phase + 1;
                phaseStart(phase) = vbl(flip);
            end
        end
        
        [keys_pressed, press_times] =...
            responseHandler(constants.device, roboResp(phase), goRobo);
        if ~isempty(keys_pressed)
            [response(phase), rt(phase), exitFlag(phase)] = ...
                wrapper_keyProcess(keys_pressed, press_times, phaseStart(phase));
            
            if strcmp(exitFlag{phase}, 'ESCAPE')
                KbQueueStop(constants.device);
                KbQueueFlush(constants.device);
                KbQueueRelease(constants.device);
                return;
            end
        end
        
    end
    
    KbQueueStop(constants.device);
    KbQueueFlush(constants.device);
    KbQueueRelease(constants.device);
    
end
