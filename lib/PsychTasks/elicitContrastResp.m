function [ tInfo, dimming_data ] = ...
    elicitContrastResp(data, tInfo, dimming_data, texes, spatial_frequency, ...
    src_rects, window, responseHandler, stim, keys,...
    constants, dst_rects, eyetrackerFcn, fb, feedbackFcn )


% default return parameters
n_flip = max(tInfo.flip);
n_dim_in_trial = length(unique(dimming_data.trial));

response = repelem({'NO_RESPONSE'}, n_dim_in_trial)';
rt = NaN(n_dim_in_trial,1);


%% start flipping stims
sides = [{'left'}, {'right'}];
accept_resp = true;
for flip = 1:n_flip
    tInfo_flip_grating = tInfo(tInfo.flip == flip, trial_type == 'grating');
    tInfo_flip_dim = tInfo(tInfo.flip == flip, trial_type == 'dim');
    
    for s = 1:2
        side = sides(s);
        tInfo_flip_side = tInfo_flip_grating(tInfo_flip_grating.side == side, :);
        d_side = data(data.side == side);
        
        % need to cleiar both canvases prior to drawing, given present blend
        % function
        [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', stim.fullWindowTex(s), 'GL_ONE', 'GL_ZERO');
        Screen('FillRect', stim.fullWindowTex(s), window.gray);
        Screen('BlendFunction', stim.fullWindowTex(s), sourceFactorOld, destinationFactorOld);
        
        % after clearing, draw gratings
        Screen('DrawTextures', stim.fullWindowTex(s), texes, [],...
            dst_rects, d_side.orientation, ...
            [], [], [], [], kPsychUseTextureMatrixForRotation, ...
            [tInfo_flip_side.phase; spatial_frequency; tInfo_flip_side.contrast; zeros(1, stim.n_gratings_per_side)]);
    end
    
    % Only draw required parts of gratings. Note that this happens in two
    % stage process because of how orientation rotations interact with
    % annulus shader
    Screen('DrawTextures', window.pointer, stim.fullWindowTex, src_rects, src_rects);
    
    % always draw central fixation cross
    drawFixation(window, stim.fixRect, stim.fixLineSize, tInfo_flip_dim.contrast);
    
    Screen('DrawingFinished', window.pointer);
    
    if accept_resp
        [keys_pressed, press_times] = ...
            responseHandler(constants.device, tInfo.roboResp{dim_count_in_trial}, tInfo.goRobo(flip));
        dimming_data.correct(dim_in_trial) = fbwrapper(dim_sequence, flip, ...
            keys_pressed, fb, feedbackFcn, keys.escape);
        
        if ~isempty(keys_pressed)
            [response{dim_count_in_trial}, rt(dim_count_in_trial), exitFlag] = ...
                wrapper_keyProcess(keys_pressed, press_times, dim_onset_in_trial(dim_count_in_trial));
            
            if strcmp(exitFlag, 'ESCAPE')
                break;
            end
        end
        accept_resp = false;
        
    elseif tInfo_flip_dim.contrast(flip) ~= tInfo_flip_dim.contrast(flip-1)
        accept_resp = true;
    end
    
    if flip == 1
        eyetrackerFcn('Message','Trial_onset');
        
        [tInfo.vbl(flip), tInfo.stimulus_onset_time(flip),...
            tInfo.flip_timestamp(flip), tInfo.missed(flip)] =...
            Screen('Flip', window.pointer, trial_start);
    else
        
        [tInfo.vbl(flip), tInfo.stimulus_onset_time(flip),...
            tInfo.flip_timestamp(flip), tInfo.missed(flip)] = ...
            Screen('Flip', window.pointer, ...
            vbl(flip-1) + ((1/stim.update_phase_sec) - 0.5) * window.ifi);
    end
    
end

% Sending a 'TRIAL_RESULT' message to mark the end of a trial in
% Data Viewer. This is different than the end of recording message
% END that is logged when the trial recording ends. The viewer will
% not parse any messages, events, or samples that exist in the data
% file after this message.
eyetrackerFcn('Message', 'TRIAL_RESULT 0');

end


function correct = fbwrapper(dim_sequence, flip, keys_pressed, fb, feedbackFcn, ignore_keys)
% provide feedback after misses and false alarms only (errors)
correct = 1;

ignore_resp = ignore_keys(keys_pressed);

if flip < 1
    return
else
    prior_flip = flip - 1;
end

if all(ignore_resp == 0)
    
    % when there is no dim & prior flip had no dim & participant responds
    if ~dim_sequence(flip) && ~dim_sequence(prior_flip) && ~isempty(keys_pressed) % false alarm
        feedbackFcn(fb.handle);
        correct = 0;
        % when there is no dim & prior flip had dim & participant responds
    elseif ~dim_sequence(flip) && dim_sequence(prior_flip) && isempty(keys_pressed) % miss
        feedbackFcn(fb.handle);
        correct = 1;
    end
end

end
