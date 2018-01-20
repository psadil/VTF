function [ data, tInfo, expParams, stairs, stim, dimming_data ] = ...
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
    
    expParams = setupExpParams(input.debugLevel, input.experiment);
    stairs = setupStaircase(input.delta_luminance_guess, expParams.nTrials);
    fb = setupFeedback();
    keys = setupKeys(input.fMRI);
    stim = setupStim(expParams, window, input);
    
    data = setupDataTable(expParams, input, stim, input.experiment);
    tInfo = setupTInfo(expParams, stim);
    
    dimming_data = setupDataDimming(expParams, input, keys);
    
    %%
    
    % show initial prompt. Timing not super critical with this one
    showPrompt(window, ['Attend to the + in the center \n', ...
        'When the + dims, press your index finger.'], 1);
    
    [triggerSent, exitFlag] = waitForStart(constants, keys, responseHandler);
    switch exitFlag{1}
        case 'ESCAPE'
            return
    end
    
    tInfo.vbl_fromTrigger_expected = tInfo.vbl_from0_expected + triggerSent;
    
    % try to flip first frame of experiment immediately
    tInfo.vbl_fromTrigger_expected(1) = tInfo.vbl_fromTrigger_expected(1) + ...
        (.5 * window.ifi);
    % for every other frame, flip according to stimulus hz
    tInfo.vbl_fromTrigger_expected(2:end) = tInfo.vbl_fromTrigger_expected(1:end-1) + ...
        ((1/stim.update_phase_sec) - 0.5) * window.ifi;
    
    for trial = 1:expParams.nTrials
        
        index_tInfo = find(tInfo.trial==trial);
        index_dimming = find(dimming_data.trial==trial);
        
        switch input.experiment
            case 'contrast'
                angles = [data.orientation_left(trial), data.orientation_right(trial)];
                contrasts = [data.contrast_left(trial), data.contrast_right(trial)];
                phases = [tInfo.phase_orientation_left(index_tInfo), tInfo.phase_orientation_right(index_tInfo)];
            case 'localizer'
                angles = [data.orientation_left1(trial), data.orientation_right1(trial),...
                    data.orientation_left2(trial), data.orientation_right2(trial)];
                contrasts = [data.contrast_left1(trial), data.contrast_right1(trial),...
                    data.contrast_left2(trial), data.contrast_right2(trial)];
                phases = [tInfo.phase_orientation_left(index_tInfo), tInfo.phase_orientation_right(index_tInfo),...
                    Shuffle(tInfo.phase_orientation_left(index_tInfo)), Shuffle(tInfo.phase_orientation_right(index_tInfo))];
        end
        
        % get luminance differ to test on this trial
        data.luminance_difference(trial) = stairs.luminance_difference(trial);
        
        % present stimuli and get responses (main task is here)
        [dimming_data.response_given(index_dimming),...
            dimming_data.rt_given(index_dimming), ...
            tInfo.vbl(index_tInfo), tInfo.missed(index_tInfo), ...
            data.exitFlag(trial),...
            data.tStart_realized(trial), ...
            dimming_data.phaseStart_realized(index_dimming)] = ...
            elicitContrastResp(...
            tInfo.vbl_fromTrigger_expected(index_tInfo),...
            window, responseHandler, stim, keys, expParams, ...
            dimming_data.roboRT_expected(index_dimming),...
            dimming_data.roboResponse_expected(index_dimming),...
            constants, phases, angles, tInfo.dimmed(index_tInfo), ...
            [1, 1 - stairs.luminance_difference(trial)], contrasts, input.experiment);
        
        if any(strcmp(data.exitFlag(trial), 'ESCAPE'))
            data = quick_clean(data, tInfo, stim);
            return
        else
            stairs.correct(trial) = ...
                analyzeResp(dimming_data.response_given(index_dimming), ...
                dimming_data.answer(index_dimming));
            
            fbwrapper(stairs.correct(trial), fb, input.fMRI);
            
            % to end, update staircase values
            stairs = update_stairs(stairs, trial);
        end
    end
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

function correct = analyzeResp( response, answer )

correct = zeros([1,length(answer)]);
for a = 1:length(answer)
    switch answer{a}
        case response{a}
            correct(a) = 1;
        otherwise
            correct(a) = 0;
    end
end
correct = all(correct);
end

function data = quick_clean(data, tInfo, stim)

data.correct(trial) = stairs.correct(trial);
data.tEnd_realized(trial) = tInfo.vbl(tInfo.flipWithinTrial==stim.nFlipsPerTrial);

end
