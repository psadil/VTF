function [ response, rt, vbl, missed, exitFlag, trial_dim ] = ...
    elicitContrastResp(texes, spatial_frequency, src_rects, vbl_expected, window, responseHandler, stim, keys,...
    roboRT, roboResp, constants, phases, angles, dim_sequence, luminance, ...
    contrasts, experiment, trial_dim, dst_rects, trial, eyetrackerFcn, fb, feedbackFcn )


%%
% default return parameters
nFlipsInTrial = size(contrasts,1);
nDimsInTrial = length(roboResp);

response = repelem({'NO_RESPONSE'},nDimsInTrial)';
exitFlag = {'EMPTY'};
rt = NaN(nDimsInTrial,1);
dim_onset_in_trial = NaN(nDimsInTrial,1);

vbl = NaN(nFlipsInTrial, 1);
missed = NaN(nFlipsInTrial, 1);


%% start flipping stims
goRobo = 0;
accept_resp = 0;
dim_count_in_trial = 0 ;
% record whether stimulus is down
% stim_down = [find(contrasts(:,1),1, 'first'), find(contrasts(:,2),1, 'first')];
KbQueueCreate(constants.device, keys.resp + keys.escape);
for flip = 1:nFlipsInTrial
    
    % need to cleiar both canvases prior to drawing, given present blend
    % function
    [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', stim.fullWindowTex_left, 'GL_ONE', 'GL_ZERO');
    Screen('FillRect', stim.fullWindowTex_left, window.gray);
    Screen('BlendFunction', stim.fullWindowTex_left, sourceFactorOld, destinationFactorOld);
    
    [sourceFactorOld, destinationFactorOld] = Screen('BlendFunction', stim.fullWindowTex_right, 'GL_ONE', 'GL_ZERO');
    Screen('FillRect', stim.fullWindowTex_right, window.gray);
    Screen('BlendFunction', stim.fullWindowTex_right, sourceFactorOld, destinationFactorOld);
    
    % after clearing, draw gratings
    Screen('DrawTextures', stim.fullWindowTex_left, texes, [],...
        dst_rects, angles(flip, 1:stim.n_gratings_per_side), ...
        [], [], [], [], kPsychUseTextureMatrixForRotation, ...
        [phases(flip, 1:stim.n_gratings_per_side); spatial_frequency;...
        repelem(contrasts(flip,1), stim.n_gratings_per_side); zeros(1, stim.n_gratings_per_side)]);
    
    Screen('DrawTextures', stim.fullWindowTex_right, texes, [],...
        dst_rects, angles(flip, 1+stim.n_gratings_per_side:end),...
        [], [], [], [], kPsychUseTextureMatrixForRotation, ...
        [phases(flip, 1+stim.n_gratings_per_side:end); spatial_frequency;...
        repelem(contrasts(flip,2), stim.n_gratings_per_side); zeros(1, stim.n_gratings_per_side)]);
    
    % Only draw required parts of gratings. Note that this happens in two
    % stage process because of how orientation rotations interact with
    % annulus shader
    Screen('DrawTextures', window.pointer, [stim.fullWindowTex_left; stim.fullWindowTex_right], ...
        src_rects, src_rects);
    
    % always draw central fixation cross
    drawFixation(window, stim.fixRect, stim.fixLineSize,...
        luminance(dim_sequence(flip)+1), experiment);
    
    Screen('DrawingFinished', window.pointer);
    
    [vbl(flip), ~, ~, missed(flip)] = Screen('Flip', window.pointer, ...
        vbl_expected(flip));
    
    if flip == 1
        eyetrackerFcn('Message','Trial_onset');
%         eyetrackerFcn('Message', '!V IMGLOAD FILL %s', [int2str(trial),'.jpg']);
        % handle special case where trial starts in sync with new dimming
        % event
        if all(dim_sequence(1:4))
            accept_resp = 1;
            dim_count_in_trial = dim_count_in_trial + 1;
            dim_onset_in_trial(dim_count_in_trial) = vbl(flip);
        end
        
        % open up response cue and allow response
        KbQueueStart(constants.device);
    else
        if dim_sequence(flip)
            if dim_sequence(flip-1)==0
                accept_resp = 1;
                dim_count_in_trial = dim_count_in_trial + 1;
                dim_onset_in_trial(dim_count_in_trial) = vbl(flip);
            end
            
            % note: dim_onset needs to be indexed by trial_dim because
            % a dimming event may have started before the present
            % experimental trial
            if (dim_count_in_trial > 0) && ... % should short-circuit when initial flips are dimms
                    ((vbl(flip) - dim_onset_in_trial(dim_count_in_trial)) > roboRT(dim_count_in_trial))
                goRobo = 1;
            end
        end
    end
    
    %     if any(stim_down(flip,1))
    %         Eyelink('Message', '!V IMGLOAD FILL %s', [int2str(trial),'both.jpg']);
    %     end
    
    if accept_resp
        [keys_pressed, press_times] = ...
            responseHandler(constants.device, roboResp{dim_count_in_trial}, goRobo);
        
        fbwrapper(dim_sequence, flip, ...
            keys_pressed, fb, feedbackFcn, keys.escape);
        
        if ~isempty(keys_pressed)
            [response{dim_count_in_trial}, rt(dim_count_in_trial), exitFlag] = ...
                wrapper_keyProcess(keys_pressed, press_times, dim_onset_in_trial(dim_count_in_trial));
            
            accept_resp = 0;
            if strcmp(exitFlag, 'ESCAPE')
                KbQueueStop(constants.device);
                KbQueueFlush(constants.device);
                KbQueueRelease(constants.device);
                
                trial_dim = dim_count_in_trial + trial_dim;
                return;
            end
            
        end
    end
    
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

trial_dim = dim_count_in_trial + trial_dim;


% Sending a 'TRIAL_RESULT' message to mark the end of a trial in
% Data Viewer. This is different than the end of recording message
% END that is logged when the trial recording ends. The viewer will
% not parse any messages, events, or samples that exist in the data
% file after this message.
eyetrackerFcn('Message', 'TRIAL_RESULT 0');


end


function fbwrapper(dim_sequence, flip, keys_pressed, fb, feedbackFcn, ignore_keys)
% provide feedback after misses and false alarms only (errors)

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
        
        % when there is no dim & prior flip had dim & participant responds
    elseif ~dim_sequence(flip) && dim_sequence(prior_flip) && isempty(keys_pressed) % miss
        feedbackFcn(fb.handle);
    end
end

end
