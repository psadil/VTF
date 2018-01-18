function [triggerSent, exitFlag] =...
    waitForStart( constants, keys, responseHandler )

KbQueueCreate(constants.device, keys.start);
KbQueueStart(constants.device);

while 1
    
    [keys_pressed, press_times] = ...
        responseHandler(constants.device, keys.robo_start, 1);
    
    if ~isempty(keys_pressed)
        triggerSent = press_times(keys_pressed(1));
        [~, ~, exitFlag] = ...
            wrapper_keyProcess(keys_pressed, press_times, GetSecs);
        break;
    end
end

KbQueueStop(constants.device);
KbQueueFlush(constants.device);
KbQueueRelease(constants.device);
end

