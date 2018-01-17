function [ data, tInfo, expParams, stairs, stim ] = ...
    runContrast( input, constants, window, responseHandler )

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
    
    Data Storage:
    Data are stored at 3 different levels.
     1) By trial/phase
      - What orientations and contrasts were to be presented on each trial
      - At what time should they have started
      - How long should the trials have lasted?
      - How long did the trials last (hopefully close to above)?
      - How many of the dimming events did the participant notice?
      - What was participants RT for each dimming event?
      - During each of the 5 trial sections, did a participant notice a
      dimming event (note that only 2 of the five phases actually included dimming)
      - How long into each phase did each participant indicate a flip?
      - At what point should (and did) each phase start?
      - How long should (and did) each phase last?

     2) According to BIDS (written during run end, using trial/phase data)
      - Trial type
      - Actual duration of trial
     3) By flip (generated at start)
      - When should (and did) each flip occur?
      - What are the parameters of the stimuli that should have been
      presented during this flip?
    
TODO:
- testing?
    %}
    
    expParams = setupExpParams(input.debugLevel, input.fMRI, input.experiment);
    stairs = setupStaircase(input.delta_luminance_guess, expParams.nTrials);
    fb = setupFeedback();
    keys = setupKeys(input.fMRI);
    stim = setupStim(expParams, window, input);
    
    data = setupDataTable(expParams, input, stim, input.experiment);
    
    tInfo = setupTInfo(expParams, stim, data);
    
    %%
    
    % show initial prompt. Timing not super critical with this one
    showPrompt(window, ['Attend to the + in the center \n', ...
        'When the + dims, press your index finger.'], 1);
    
    [triggerSent, exitFlag] = waitForStart(constants, keys, responseHandler);
    switch exitFlag{1}
        case 'ESCAPE'
            return
    end
    
    for trial = 1:expParams.nTrials
        
        index_tInfo = 0;
        if trial == 1
            firstFlipTime = triggerSent;
        else
            firstFlipTime = tInfo.vbl(index_tInfo(end)+1);
        end
        index_data = find_index(trial, expParams.nPhasePerTrial, 0);
        index_tInfo = find_index(trial, stim.nFlipsPerTrial, 1);
        angles = [data.orientation_left(index_data(1)), data.orientation_right(index_data(1))];
        contrasts = [data.contrast_left(index_data(1)), data.contrast_right(index_data(1))];
        
        % get luminance differ to test on this trial
        data.luminance_difference(index_data) = stairs.luminance_difference(trial);
        
        % present stimuli and get responses (main task is here)
        [data.response_given(index_data), data.rt_given(index_data), ...
            tInfo.vbl(index_tInfo), tInfo.missed(index_tInfo), ...
            data.exitFlag(index_data), data.tStart_realized(index_data), ...
            data.phaseStart_realized(index_data)] = ...
            elicitContrastResp(firstFlipTime, window, responseHandler, stim,...
            keys, expParams, data.roboRT_expected(index_data), data.roboResponse_expected(index_data), constants,...
            [tInfo.phase_orientation_left(index_tInfo), tInfo.phase_orientation_right(index_tInfo)],...
            angles, tInfo.dimmed(index_tInfo), [1, 1 - stairs.luminance_difference(trial)], contrasts);
        
        if any(strcmp(data.exitFlag(index_data), 'ESCAPE'))
            return
        else
            stairs.correct(trial) = all(data.correct(index_data));
            data.correct(index_data) = analyzeResp(data.response_given(index_data), data.answer(index_data));
            fbwrapper(stairs.correct(trial), fb, input.fMRI);
            
            % draw and flip regular fixation
            drawFixation(window, stim.fixRect, stim.fixLineSize, 1);
            [tInfo.vbl(index_tInfo(end)+1), ~, ~, tInfo.missed(index_tInfo(end)+1)] = ...
                Screen('Flip', window.pointer, ...
                tInfo.vbl(index_tInfo(end)) + ((1/stim.update_phase_sec) - 0.5) * window.ifi);
            % wait ITI (allowing escape response)
            exitFlag = soakTime( keys.escape, tInfo.vbl(index_tInfo(end)+1),...
                expParams.iti_dur_sec, responseHandler, constants );
            if strcmp(exitFlag{1}, 'ESCAPE')
                return
            end
        end
        
        % update QUEST parameters based on whether all phases were correct
        stairs = update_stairs(stairs, trial);
        data.tEnd_realized(index_data) = GetSecs;
        
    end
    constants.endStimTime = GetSecs;
    
    % wait post dur
    exitFlag = soakTime( keys.escape, tInfo.vbl(index_tInfo(end)+1), ...
        expParams.iti_dur_sec, responseHandler, constants );
    if strcmp(exitFlag{1}, 'ESCAPE')
        return
    end
    
    tInfo.vbl = tInfo.vbl - triggerSent;
    data.tStart_realized = data.tStart_realized - triggerSent;
    data.phaseStart_realized = data.phaseStart_realized - triggerSent;
    
end


function data_index = find_index(trial, nEventsPerTrial, nEventsPerITI)

data_index = (1+(nEventsPerTrial*(trial-1)) + (nEventsPerITI*(trial-1)) ):...
    ((nEventsPerTrial*(trial)) + (nEventsPerITI*(trial-1)) );

end

function fbwrapper(correct, fb, fMRI)

if ~fMRI
    if correct
        give_feedback_tone(fb.correct_hz);
    else
        give_feedback_tone(fb.incorrect_hz);
    end
end

end

function stairs = update_stairs(stairs, trial)

if stairs.correct(trial)
    % make task more difficult
    location = find(stairs.options == stairs.luminance_difference(trial));
    if location > 2
        location = location - 2;
    elseif location == 2 || location == 1
        location = 1;
    end
    stairs.luminance_difference(trial+1) = stairs.options(location);
else
    % make task a bit easier (but only if there's room to do so)
    location = find(stairs.options == stairs.luminance_difference(trial));
    if location < length(stairs.options)
        location = location + 1;
    end
    stairs.luminance_difference(trial+1) = stairs.options(location);
end

end

