function [ response, rt, vbl, missed, exitFlag, trial_dim ] = ...
    elicitContrastResp(texes, spatial_frequency, src_rects, vbl_expected, window, responseHandler, stim, keys,...
    roboRT, roboResp, constants, phases, angles, dim_sequence, luminance, contrasts, experiment, trial_dim )




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
KbQueueCreate(constants.device, keys.resp + keys.escape);
for flip = 1:nFlipsInTrial
    
    
    
    switch experiment
        case 'contrast'
            Screen('DrawTextures', stim.fullWindowTex_left, texes, [],...
                stim.dstRects, angles(flip, 1),...
                [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                [phases(flip, 1:stim.n_gratings_per_side); spatial_frequency;...
                repelem(contrasts(flip,1), stim.n_gratings_per_side); zeros(1,stim.n_gratings_per_side)]);
            Screen('DrawTextures', stim.fullWindowTex_right, texes, [],...
                stim.dstRects, angles(flip, 2),...
                [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                [phases(flip, 1+stim.n_gratings_per_side:end); spatial_frequency;...
                repelem(contrasts(flip,2), stim.n_gratings_per_side); zeros(1,stim.n_gratings_per_side)]);
            
            % Batch-Draw the required parts of the mediating textures to onscreen
            % window
            Screen('DrawTextures', window.pointer, [stim.fullWindowTex_left; stim.fullWindowTex_right], ...
                src_rects, src_rects);
            
        case 'localizer'
            
            for grating = 1:5
                
                % after drawing the first grating, clear a circular,
                % to-be-drawn-in region
                if grating > 1
                    [sourceFactorOld, destinationFactorOld] = ...
                        Screen('Blendfunction', window.pointer, GL_ONE, GL_ZERO);
                    
                    Screen('FillOval', window.pointer, [0.5, 0.5, 0.5, 1], ...
                        src_rects(:,grating));
                    
                    % reset to regular blending function
                    Screen('Blendfunction', window.pointer, sourceFactorOld, destinationFactorOld, [1 1 1 1]);
                end
                
                Screen('DrawTextures', window.pointer, texes(grating), [],...
                    repmat(stim.dstRects,[1,2]), angles(flip, :), ...
                    [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                    [squeeze(phases(flip, grating, :))'; spatial_frequency(grating,:);...
                    contrasts(flip, :); zeros(1, 2)]);
                
            end
            [sourceFactorOld, destinationFactorOld] = ...
                Screen('Blendfunction', window.pointer, GL_ONE, GL_ZERO);
            Screen('FillRect', window.pointer, window.gray, stim.strip);
            Screen('Blendfunction', window.pointer, sourceFactorOld, destinationFactorOld);
            
    end
    
    % always draw central fixation cross
    drawFixation(window, stim.fixRect, stim.fixLineSize,...
        luminance(dim_sequence(flip)+1), experiment);
    
    Screen('DrawingFinished', window.pointer);
    
    [vbl(flip), ~, ~, missed(flip)] = Screen('Flip', window.pointer, ...
        vbl_expected(flip));
    
    if flip == 1
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
    
    if accept_resp
        [keys_pressed, press_times] = ...
            responseHandler(constants.device, roboResp{dim_count_in_trial}, goRobo);
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
end
