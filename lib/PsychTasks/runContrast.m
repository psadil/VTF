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
    Onsets and trial durations were precalculated with genetic algorithm.
    This includes both the main stimulation (oriented gratings of varying
    levels of contrast) which is stored in table data, as well as
    incidental dimming task which is stored in dimming_data table.
    
    the table tInfo is calculated to contain by-flip stimulus information.
    This makes it relatively easy to figure out what each frame of the
    experiment should be doing (amd debug which ones aren't doing that).
    
    Note that the column contrast from data is upsampled into tInfo.
    Upsampling enables handling of variable trial and SOA duration.
    Specifically, each trial can then be thought of as a joint stimulus +
    baseline, throughout which the incidental dimming task continues
    without interuption. The flips with no gratings are accomplished by
    setting contrast to 0 for those flips (hence upsampling contrast to
    flip-time)
    
    %}
    
    
    expParams = setupExpParams(input.debugLevel, input.experiment, constants);
    stairs = setupStaircase(input.delta_luminance_guess, expParams.nTrials);
    fb = setupFeedback();
    keys = setupKeys(input.fMRI);
    stim = setupStim(expParams, window, input);
    
    data = setupDataTable(expParams, input.subject, input.experiment, constants);
    dimming_data = setupDataDimming(expParams, keys, data, constants, input.experiment, input.responder, input.subject);
    tInfo = setupTInfo( expParams, stim, data, dimming_data, input, constants );
    
    
    %%
    switch input.responder
        case 'setup'
            return
        otherwise
            % show initial prompt. Timing not super critical with this one
            showPrompt(window, ['Attend to the + in the center \n', ...
                'When the + dims, press your index finger.'], 1);
            
            [triggerSent, exitFlag] = waitForStart(constants, keys, responseHandler);
            switch exitFlag{1}
                case 'ESCAPE'
                    return
            end
            
            tInfo.vbl_expected_fromTrigger = tInfo.vbl_expected_from0 + triggerSent;
            
            slack = .5;
            % try to flip first frame of experiment immediately
            tInfo.vbl_expected_fromTrigger(1) = tInfo.vbl_expected_fromTrigger(1) + ...
                (slack * window.ifi);
            % for every other frame, flip according to stimulus hz
            tInfo.vbl_expected_fromTrigger(2:end) = tInfo.vbl_expected_fromTrigger(1:end-1) + ...
                ((1/stim.update_phase_sec) - slack) * window.ifi;
            
            trial_dim = 0;
            for trial = 1:expParams.nTrials
                
                index_tInfo = find(tInfo.trial==trial);
                index_dimming = find(dimming_data.trial_exp==trial);
                index_data = find(data.trial == trial);
                
                switch input.experiment
                    case 'contrast'
                        angles = [repmat(tInfo.orientation_left(index_tInfo), [1, stim.n_gratings_per_side]),...
                           repmat(tInfo.orientation_right(index_tInfo), [1, stim.n_gratings_per_side])];
                        contrasts = [tInfo.contrast_left(index_tInfo),...
                            tInfo.contrast_right(index_tInfo)];
                        
                    case 'localizer'
                        angles = repmat([tInfo.orientation_1(index_tInfo), ...
                            tInfo.orientation_2(index_tInfo)], ...
                            [1, stim.n_gratings_per_side]);
                        contrasts = repmat(tInfo.contrast(index_tInfo), [1, 2]);
                end

                texes = repmat(stim.tex, [stim.reps_per_grating, 1]);
                spatial_frequency = repmat(stim.grating_freq_cpp, [1, stim.reps_per_grating]);
                phases = repmat([tInfo{index_tInfo, contains(tInfo.Properties.VariableNames, 'phase_orientation_left_')},...
                    tInfo{index_tInfo, contains(tInfo.Properties.VariableNames, 'phase_orientation_right_')}], [1, stim.reps_per_grating]);

                src_rects = [stim.srcRect_left, stim.srcRect_right];

                % get luminance differ to test on this trial
                data.luminance_difference(index_data) = ...
                    repelem(stairs.luminance_difference(trial), length(index_data))';
                
                % present stimuli and get responses (main task is here)
                [dimming_data.response_given(index_dimming), ...
                    dimming_data.rt_given(index_dimming), ...
                    tInfo.vbl(index_tInfo), tInfo.missed(index_tInfo), ...
                    data.exitFlag(index_data), trial_dim] = ...
                    elicitContrastResp(...
                    texes, spatial_frequency, src_rects, tInfo.vbl_expected_fromTrigger(index_tInfo),...
                    window, responseHandler, stim, keys, ...
                    dimming_data.roboRT_expected(index_dimming),...
                    dimming_data.roboResponse_expected(index_dimming),...
                    constants, phases, angles, tInfo.dim(index_tInfo), ...
                    [1, 1 - stairs.luminance_difference(trial)], contrasts,...
                    input.experiment, trial_dim, stim.dstRects);
                
                stairs.correct(trial) = ...
                    analyzeResp(dimming_data.response_given(index_dimming), ...
                    dimming_data.answer(index_dimming));
                data.correct(index_data) = repelem(stairs.correct(trial), length(index_data))';
                
                if any(strcmp(data.exitFlag(index_data), 'ESCAPE'))
                    [data, dimming_data] = ...
                        quick_clean(data, tInfo, dimming_data, trial, trial_dim, input.experiment);
                    return
                else
                    fbwrapper(stairs.correct(trial), fb, input.fMRI);
                    
                    % to end, update staircase values
                    stairs = update_stairs(stairs, trial);
                end
            end
            [data, dimming_data] = quick_clean(data, tInfo, dimming_data, trial, trial_dim, input.experiment);
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

function [data, dimming_data] = quick_clean(data, tInfo, dimming_data, trial, trial_dim, experiment)


switch experiment
    case 'contrast'
        for t = 1:trial
            index_data = find(data.trial == t);
            
            data.tStart_realized(index_data) = ...
                repelem(tInfo.vbl(find(tInfo.trial==t,1,'first')), length(index_data));
            data.tEnd_realized(index_data) = ...
                repelem(tInfo.vbl(find(tInfo.trial==t & ...
                (tInfo.contrast_left > 0 & tInfo.contrast_right > 0 ),1,'last') + 1), length(index_data));
        end
        
    case 'localizer'
        for t = 1:trial
            index_data = find(data.trial == t);
            
            data.tStart_realized(index_data) = ...
                repelem(tInfo.vbl(find(tInfo.trial==t,1,'first')), length(index_data));
            data.tEnd_realized(index_data) = ...
                repelem(tInfo.vbl(find(tInfo.trial==t & tInfo.contrast > 0,1,'last') + 1), length(index_data));
        end
end

for t = 1:trial_dim
    
    dimming_data.tStart_realized(dimming_data.trial==t) = ...
        tInfo.vbl(find(tInfo.trial_dim==t,1,'first'));
    dimming_data.tEnd_realized(dimming_data.trial==t) = ...
        tInfo.vbl(find(tInfo.trial_dim==t,1,'last') + 1);
end

end
