function stim = setupStim( expParams, window, input )

stim.maxJitterAngle = 3*pi/180;
stim.tempFreq = 10; % in Hz

% this is the contrast of the standard, all target contrasts will be relative to this
stim.contrast = [.3, .8];

stim.fixSizeDeg = .4;
stim.fixLineSize = 2;

%stimulus properties
stim.offXDeg = 0;                  % abs x offset of stimulus aperture from center in degrees
stim.offYDeg = 0;                % abs y offset of stimulus aperture from center in degrees
%grating params (in degrees)
stim.stimSizeDeg = 10;  % stim size in degrees (radius)

stim.n = 2048;
[stim.x, stim.y] = meshgrid(linspace(-1,1,stim.n));
stim.innerR = .025;
stim.sf = 5;           % cycles/image
stim.sig = .33;        % 1/e half width of gaussian

% directions presented 
stim.targOrients = linspace(0,180-(180/expParams.numOrients), expParams.numOrients)*pi/180;

stim.fixColor = window.white;

% length of the lines
stim.fixSizeDeg = .25;

stim = wrapper_deg2pix(stim, window);

% Definition of the drawn source rectangle on the screen:
stim.srcRect = [window.xCenter - stim.offXPix - stim.stimSizePix,...
    window.yCenter - stim.offYPix - stim.stimSizePix,...
    window.xCenter - stim.offXPix + stim.stimSizePix,...
    window.yCenter - stim.offYPix + stim.stimSizePix];

% cue point coordinates
stim.fixRect = ...
    [(window.xCenter  - stim.fixSizePix),...
    (window.yCenter - stim.fixSizePix),...
    (window.xCenter  + stim.fixSizePix),...
    (window.yCenter + stim.fixSizePix)];

% flicker sequence
stim.nFlipsPerSecOfStim = ceil(input.refreshRate / stim.tempFreq);
stim.nTicksPerStim = ceil(expParams.stimDur * stim.nFlipsPerSecOfStim);

stim.flicker = repmat([0;1],[stim.nTicksPerStim/2,1]);


% number of flips in a trial will equal
% 2x the number of flips in a grating presentation
% plus the number of delays (2)
% plus 1 at end of trial
stim.nFlipsPerTrial = length(stim.flicker)*2 + 2 + 1;

end

function stim = wrapper_deg2pix(stim, window)

stim.fixSizePix = deg2pix(stim.fixSizeDeg, window);
stim.stimSizePix = deg2pix(stim.stimSizeDeg, window);
stim.fixSizePix = deg2pix(stim.fixSizeDeg, window);
stim.offXPix = deg2pix(stim.offXDeg, window);
stim.offYPix = deg2pix(stim.offXDeg, window);
stim.stimSizePix = deg2pix(stim.stimSizeDeg, window);

end

