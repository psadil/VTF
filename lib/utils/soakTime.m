function exitFlag = ...
    soakTime( keys, from, duration, responseHandler, constants )

% soakTime: wrapper around responseHandler and wrapper_keyProcess to
% collect responses only for certain duration, without affecting whatever
% is presented on the screen.

%%
exitFlag = {'OK'};
KbQueueCreate(constants.device, keys);
KbQueueStart(constants.device);

while GetSecs <= from + duration
    
    [keys_pressed, press_times] = ...
        responseHandler(constants.device, 'z', 1);
    
    if ~isempty(keys_pressed)
        [~, ~, exitFlag] = ...
            wrapper_keyProcess(keys_pressed, press_times, from);
        break;
    end
    
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);

end

