function window = setupWindow(constants, input)

% viewing distance and screen width, in CM...used to convert degrees visual
% angle to pixel units later on for drawing stuff
if input.fMRI
    window.screenWidthCM = 70;
    window.vDistCM = 137;
    window.res_input = [1920, 1080];
else
    window.screenWidthCM = 34.29;
    window.vDistCM = 50.8;
end


%%
window.screenNumber = max(Screen('Screens')); % Choose a monitor to display on
window.oldRes = Screen('Resolution',window.screenNumber,[],[],input.refreshRate); % get screen resolution, set refresh rate

correctGamma = linspace(0,1,256)';
window.LUT = correctGamma*255; %LUT is look-up-table

window.bckGrnd = window.LUT(round(window.bckGrnd*255));

%Start setting up the display
AssertOpenGL; % bail if current version of PTB does not use OpenGL


window.black = BlackIndex(s);
window.white = WhiteIndex(s);
window.gray=ceil((window.white+window.black)/2);
if round(window.gray)==window.white
    window.gray=window.black;
end

% find the 'real' value for gray after gamma correction using our
% Look-Up-Table. This gray will be used for the background so that our
% gaussian-windowed grating blend in smoothly with the background
window.gray = window.LUT(window.gray);

[window.pointer, window.winRect] = ...
    Screen('OpenWindow', window.screenNumber, window.gray);

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

Screen('TextFont',window.pointer, 'Arial');
Screen('TextSize',window.pointer, window.fontSize);
Screen('TextStyle', window.pointer, 0);
Screen('TextColor', window.pointer, window.black);
Screen('TextBackgroundColor', window.pointer, window.gray);


end

function checkRefreshRate(trueHertz, requestedHertz, constants)

if abs(trueHertz - requestedHertz) > 2
    windowCleanup(constants);
    disp('Set the refresh rate to the requested rate')
end

end
