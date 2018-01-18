function window = setupWindow(constants, input)


% viewing distance and screen width, in CM...used to convert degrees visual
% angle to pixel units later on for drawing stuff
if input.fMRI
    % https://www.umass.edu/ials/sites/default/files/hmrc_tn_bold_screen_view_angle.pdf
    window.screen_w_cm = 35;
    window.screen_h_cm = 19.6;
    window.view_distance_cm = 137;
else
    % MSI parameters
    window.screen_w_cm = convlength(15.5,'in','m')*100;
    window.screen_h_cm = convlength(8.98,'in','m')*100;
    window.view_distance_cm = convlength(24,'in','m')*100;
end


%%
window.screenNumber = max(Screen('Screens')); % Choose a monitor to display on
% get screen resolution, set refresh rate
window.oldRes = Screen('Resolution',window.screenNumber,[],[],input.refreshRate);

window.black = BlackIndex(window.screenNumber);
window.white = WhiteIndex(window.screenNumber);
window.gray = GrayIndex(window.screenNumber);

PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange', 1);
% need 32Bit for proper alpha blending, which only barely happens here (and
% maybe not at all). Though, this asks for the higher precision nicely, and
% defaults to 16 if not possible
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
switch input.debugLevel
    case 1
%         Screen('Preference', 'SkipSyncTests', 1);
        [window.pointer, window.winRect] = ...
            PsychImaging('OpenWindow', window.screenNumber, window.gray);
    case 10
        Screen('Preference', 'SkipSyncTests', 1);
        [window.pointer, window.winRect] = ...
            PsychImaging('OpenWindow', window.screenNumber, window.gray, [0, 0, 1920, 600]);
    case 0
        [window.pointer, window.winRect] = ...
            PsychImaging('OpenWindow', window.screenNumber, window.gray);
end
% Make sure the GLSL shading language is supported:
AssertGLSL;

topPriorityLevel = MaxPriority(window.pointer);
Priority(topPriorityLevel);

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

% Screen('TextFont',window.pointer, 'Arial');
Screen('TextSize',window.pointer, window.fontSize);
% Screen('TextStyle', window.pointer, 1); % 0=normal,1=bold,2=italic,4=underline,8=outline,32=condense,64=extend.
Screen('TextColor', window.pointer, window.white);


end

function checkRefreshRate(trueHertz, requestedHertz, constants)

if abs(trueHertz - requestedHertz) > 2
    windowCleanup(constants);
    disp('Set the refresh rate to the requested rate')
end

end
