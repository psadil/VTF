function [ response, rt, vbl, missed, exitFlag, trial_dim ] = ...
    elicitContrastResp(vbl_expected, window, responseHandler, stim, keys,...
    roboRT, roboResp, constants, phases, angles, dim_sequence, luminance, contrasts, experiment, trial_dim )

%{
        
    %}
    
    
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
        
        % Batch-Draw all gratings
        % drawn with 0 contrast
        Screen('DrawTextures', window.pointer, stim.tex, [],...
            stim.dstRects, angles(flip,:), [], [], [], [], [], ...
            [phases(flip,:); repelem(stim.grating_freq_cpp, stim.n_gratings);...
            contrasts(flip,:); zeros(1,stim.n_gratings)]);
        
        % always draw central fixation cross
        drawFixation(window, stim.fixRect, stim.fixLineSize, luminance(dim_sequence(flip)+1), experiment);
        
        Screen('DrawingFinished', window.pointer);
        
        [vbl(flip), ~, ~, missed(flip)] = Screen('Flip', window.pointer, ...
            vbl_expected(flip));
        
        if flip == 1
            % handle special case where trial starts in sync with dimming
            % event
            if dim_sequence(1:4)
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
