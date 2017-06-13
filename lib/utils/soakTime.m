function [response, rt, exitFlag] = ...
    soakTime( keys, from, duration, ...
    response, rt, exitFlag, responseHandler, constants )

% soakTime: wrapper around responseHandler and wrapper_keyProcess to
% collect responses only for certain duration, without affecting whatever
% is presented on the screen.

%%
KbQueueCreate(constants.device, keys);
KbQueueStart(constants.device);

while GetSecs <= from + duration
    
    if isempty(response{1})
        [keys_pressed, press_times] = ...
            responseHandler(constants.device, 'z', 1);
        
        if ~isempty(keys_pressed)
            [response, rt, exitFlag] = ...
                wrapper_keyProcess(keys_pressed, press_times, from);
            break;
        end
        
    end
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

end

