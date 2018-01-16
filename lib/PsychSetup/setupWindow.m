function window = setupWindow(constants, input)
PsychDefaultSetup(2);

% viewing distance and screen width, in CM...used to convert degrees visual
% angle to pixel units later on for drawing stuff
if input.fMRI
    window.screenWidthCM = 70;
    window.vDistCM = 137;
%     window.res_input = [1920, 1080];
else
    window.screenWidthCM = 34.29;
    window.vDistCM = 50.8;
end


%%
window.screenNumber = max(Screen('Screens')); % Choose a monitor to display on
window.oldRes = Screen('Resolution',window.screenNumber,[],[],input.refreshRate); % get screen resolution, set refresh rate


switch input.debugLevel
    case 0
        [window.pointer, window.winRect] = ...
            Screen('OpenWindow', window.screenNumber, 127);
    otherwise
        Screen('Preference', 'SkipSyncTests', 1);
        [window.pointer, window.winRect] = ...
            Screen('OpenWindow', window.screenNumber, 127, [0, 0, 1920, 600]);
end

% these need to be called after OpenWindow, otherwise colors will still be
% 0-255
window.black = BlackIndex(window.screenNumber);
window.white = WhiteIndex(window.screenNumber);
window.gray = GrayIndex(window.screenNumber);

topPriorityLevel = MaxPriority(window.pointer);
Priority(topPriorityLevel);

% enable blending (needed so that neighboring textures show proper grey
% background)
Screen('BlendFunction', window.pointer, GL_ONE, GL_ONE);

% define some landmark locations to be used throughout
[window.xCenter, window.yCenter] = RectCenter(window.winRect);

% Get some the inter-frame interval, refresh rate, and the size of our window
window.ifi = Screen('GetFlipInterval', window.pointer);
window.hertz = FrameRate(window.pointer); % hertz = 1 / ifi
window.width = RectWidth(window.winRect);
window.height = RectHeight(window.winRect);

checkRefreshRate(window.hertz, input.refreshRate, constants);

% Font Configuration
window.fontSize = 24;

Screen('TextFont',window.pointer, 'Arial');
Screen('TextSize',window.pointer, window.fontSize);
Screen('TextStyle', window.pointer, window.black);
Screen('TextColor', window.pointer, window.white);
% Screen('TextBackgroundColor', window.pointer, window.gray);


end

function checkRefreshRate(trueHertz, requestedHertz, constants)

if abs(trueHertz - requestedHertz) > 2
    windowCleanup(constants);
    disp('Set the refresh rate to the requested rate')
end

end
