function [ tInfo, stairs, stim, el ] = ...
    runContrast( input, constants, window, responseHandler, eyetrackerFcn )

%{
Main experiment

Overall Flow:
    On each trial, two grating stimuli are presented and participants must
    complete a luminance change detection paradigm. Trials are separated by
    a set ITI, and the change in luminance is staircased.
    
    Within a Trial:
    All timing is set prior to each trial. Parameters that change depending
    on the flip are stored in the tInfo structure, which also stores the
    timing (or missed flips) that was actually acheived.
 
    %}
    
    
    % show initial prompt. Timing not super critical with this one
    showPrompt(window, 'Initializing...', false);
    
    [feedbackFcn, fb] = makeFeedbackFcn(input.give_feedback);
    keys = setupKeys(input.fMRI);
    stim = setupStim( window, input);
    
    tInfo = setupTInfo( constants, stim );
    
    index_dim = tInfo.trial_type == 'dim';
    tInfo_dim = tInfo(index_dim,:);
    index_grating = tInfo.trial_type == 'grating';
    tInfo_grating = tInfo(index_grating,:);
    
    sides = [{'left'}; {'right'}];
    n_flip = max(tInfo.flip);
    
    stairs = setupStaircase(input.delta_luminance_guess);
    
    slack = 0.5;
    flip_schedule_offset = (stim.flips_per_update - slack) * window.ifi;
    
    [el, exitflag] = setupEyeTracker( input.tracker, window, constants );
    if strcmp(exitflag, 'ESC')
        return;
    end
    %%
    
    startup(eyetrackerFcn);
    
    % show initial prompt. Timing not super critical with this one
    showPrompt(window, ['Attend to the + in the center \n', ...
        'When the + dims, press your index finger.'], 1);
    
    % trigger sent isn't used until way later, when we're trying to show
    % stimuli
    [triggerSent, exitflag] = waitForStart(constants, keys, responseHandler);
    switch exitflag{1}
        case 'ESCAPE'
            cleanup(eyetrackerFcn, constants);
            return
        otherwise
            % mark zero-plot time in data file
            eyetrackerFcn('message', 'SYNCTIME');
    end
    
    % little helper vectors for auxillary parameters in the procedural
    % grating step. sacraficed clarity for what I hope will be a speed
    % boost
    zz = zeros(1, stim.n_gratings_per_side);
    oo = ones(1, stim.n_gratings_per_side);
    
    % open up response cue and allow response. these would go in the
    % startup function, but ptb seemed to complain when the creation
    % function wasn't called in the same environment as the checking
    % function
    KbQueueCreate(constants.device, keys.resp + keys.escape);
    KbQueueStart(constants.device);
    for flip = 1:n_flip
        
        
        %% start flipping stims
        
        % we subset the larger dataframe when many sets of parameters will
        % be pulled from that single subset
        index_grating_flip = tInfo_grating.flip == flip;
        
        switch tInfo_dim.event{flip}
            case 'trial_start'
                index_dim_trial = flip:(flip+9);
                tInfo_dim.contrast( flip:(flip+3) ) = ...
                    repmat(1 - stairs.luminance_difference, [4, 1]);
            case 'base_resp_close'
                result = any(strcmp(tInfo_dim.response(index_dim_trial),...
                    tInfo_dim.answer{index_dim_trial(1)}));
                
                fbwrapper(result, feedbackFcn, 'fb');
                % update staircase values for next trial
                stairs = update_stairs(stairs, result);
        end
        
        for s = 1:2
            side = sides(s);
            index_grating_flip_side = (tInfo_grating.side == side) & index_grating_flip;
            
            % need to clear both canvases prior to drawing, given present blend
            % function
            [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', stim.fullWindowTex(s), 'GL_ONE', 'GL_ZERO');
            Screen('FillRect', stim.fullWindowTex(s), window.gray);
            Screen('BlendFunction', stim.fullWindowTex(s), sourceFactorOld, destinationFactorOld);
            
            % after clearing, draw gratings
            Screen('DrawTextures', stim.fullWindowTex(s), stim.texes, [],...
                stim.dst_rects, tInfo_grating.orientation(index_grating_flip_side,:), ...
                [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                [tInfo_grating.phase(index_grating_flip_side,:); stim.spatial_frequency;...
                oo * tInfo_grating.contrast(index_grating_flip_side,:); zz]);
        end
        
        % Only draw required parts of gratings. Note that this happens in two
        % stage process because of how orientation rotations interact with
        % annulus shader
        Screen('DrawTextures', window.pointer, stim.fullWindowTex, stim.src_rects, stim.src_rects);
        
        % always draw central fixation cross
        drawFixation(window, stim.fixRect, stim.fixLineSize, tInfo_dim.contrast(flip));
        
        % signal that no more drawing will occur on this flip and let gpu
        % get to work. meanwhile, handle other business before flipping
        Screen('DrawingFinished', window.pointer);
        
        
        if flip == 1
            % after trigger is sent, try to flip on next refresh cycle. All
            % subsequent flips will be based on this event
            flip_when = triggerSent + (1 - slack) * window.ifi;
        else
            flip_when = tInfo_dim.vbl(flip - 1) + flip_schedule_offset;
        end
        [tInfo_dim.vbl(flip), tInfo_dim.stimulus_onset_time(flip),...
            tInfo_dim.flip_timestamp(flip), tInfo_dim.missed(flip)] = ...
            Screen('Flip', window.pointer, flip_when);
        
        [keys_pressed, press_times] = ...
            responseHandler(constants.device, tInfo_dim.answer{flip}, 1);
        
        if ~isempty(keys_pressed)
            [tInfo_dim.response(flip), ...
                tInfo_dim.press_time(flip), ...
                tInfo_dim.exitflag(flip)] = ...
                wrapper_keyProcess_noRT(keys_pressed, press_times);
            
            if strcmp(tInfo_dim.exitflag{flip}, 'ESCAPE')
                tInfo = rebuild_tInfo(tInfo_grating, tInfo_dim);
                cleanup(eyetrackerFcn, constants, fb);
                return;
            end
        end
        
        % was the response correct?
        tInfo_dim.correct(flip) = ...
            strcmp(tInfo_dim.response{flip}, tInfo_dim.answer{flip});
        
        % give feedback at flip rate when no dim. That is, play tone whenever
        % participant does not have NO RESPONSE when there is a dim, or
        % has a response when a dim has not happened
        fbwrapper(tInfo_dim.correct(flip), feedbackFcn, tInfo_dim.event{flip});
        
        switch tInfo_grating.event{index_grating_flip_side}
            case 'trial_start'
                eyetrackerFcn('Message','Trial_onset');
                eyetrackerFcn('Message', 'TRIALID %d', tInfo_grating.trial(index_grating_flip_side));
                eyetrackerFcn('Message','!V TRIAL_VAR %s %d', 'trial', tInfo_grating.trial(index_grating_flip_side));
            case 'return_to_base_contrast'
                % Sending a 'TRIAL_RESULT' message to mark the end of a trial in
                % Data Viewer. This is different than the end of recording message
                % END that is logged when the trial recording ends. The viewer will
                % not parse any messages, events, or samples that exist in the data
                % file after this message.
                eyetrackerFcn('Message', 'TRIAL_RESULT 0');
        end
        
    end
    
    tInfo = rebuild_tInfo(tInfo_grating, tInfo_dim);
    cleanup(eyetrackerFcn, constants, fb);
end

function tInfo = rebuild_tInfo(tInfo_grating, tInfo_dim)

tInfo_grating.vbl(tInfo_grating.side == 'left') = tInfo_dim.vbl;
tInfo_grating.vbl(tInfo_grating.side == 'right') = tInfo_dim.vbl;

tInfo = [tInfo_grating; tInfo_dim];

end

function stairs = update_stairs(stairs, result)

step_more_difficult = 1;
step_less_difficult = 3;

n_options = length(stairs.options);

if result
    % make task more difficult
    location = find(stairs.options == stairs.luminance_difference);
    if location > 2
        location = location - step_more_difficult;
    elseif location <= 2
        location = 1;
    end
else
    % make task a bit easier (but only if there's room to do so)
    location = find(stairs.options == stairs.luminance_difference);
    if (location + step_less_difficult) < n_options
        location = location + step_less_difficult;
    else
        location = n_options;
    end
end

stairs.luminance_difference = stairs.options(location);

end

function startup(eyetrackerFcn)

% Must be offline to draw to EyeLink screen
eyetrackerFcn('Command', 'set_idle_mode');

% clear tracker display and draw background img to host pc
eyetrackerFcn('Command', 'clear_screen 0');

% image file should be 24bit or 32bit bitmap
% parameters of ImageTransfer:
% imagePath, xPosition, yPosition, width, height, trackerXPosition, trackerYPosition, xferoptions
% VERY SLOW. Should only be done when not recording
% eyetrackerFcn('ImageTransfer', stim.background_img_filename);

eyetrackerFcn('StartRecording');

% always wait a moment for recording to definitely start
WaitSecs(0.1);

end

function cleanup(eyetrackerFcn, constants, fb)

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);
eyetrackerFcn('Command', 'set_idle_mode');

PsychPortAudio('Close', fb.handle);

end

function fbwrapper(correct, feedbackFcn, event)
% provide feedback after misses and false alarms only (errors)

% the event flag is to help make sure that a miss is only indicated once
% per opportunity, at the end of the dimming trial
if ~correct && ~(any(strfind(event, 'trial')) || any(strfind(event, 'return_to_base_contrast')))
    feedbackFcn();
end

end

