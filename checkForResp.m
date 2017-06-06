function [resp, ts] = checkForResp(possResp)
% queries the keyboard to see if a legit response was made
% returns the response and the timestamp
resp = 0;
ts = nan;
[keyIsDown, secs, keyCode] = KbCheck;

if sum(keyCode)>=1   % if at least one key was pressed
    keysPressed = find(keyCode);
    % in the case of multiple keypresses, just consider the first one
    if find(keysPressed(1)==possResp)
        resp = keysPressed(1);
        ts = secs;
    end
end