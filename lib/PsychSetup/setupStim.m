function stim = setupStim( expParams, window, input )

% rate at which stimulus will constantly flicker
stim.tempFreq = 10;

% degree size of fixation
stim.fixSizeDeg = .25;
stim.fixLineSize = 2;

% amount by which stimuli will be offset from center
stim.offXDeg = 0;                  
stim.offYDeg = 0; 

% stim size in degrees (radius)
stim.stimSizeDeg = 10;

% number of pixels used to draw the stimulus
stim.n = 2048;
[stim.x, stim.y] = meshgrid(linspace(-1,1,stim.n));

% radius of inner annulus as proportion of total size
stim.innerR = .25;

% cycles/image within the grating stimulus (higher value indicates tighter
% bands)
stim.sf = 5;

switch input.experiment
    case 'contrast'
        stim.maxJitterAngle = 3*pi/180;
        
        % this is the contrast of the standard, all target contrasts will be relative to this
        stim.contrast = [.3, .8];
        
        % directions presented
        stim.targOrients = linspace(0,180-(180/expParams.numOrients), expParams.numOrients)*pi/180;
        
        stim.fixColor = window.white;
        
        % 1/e half width of gaussian
        stim.sig = .33;
        
    case 'localizer'
        
        % 1/e half width of gaussian
        stim.sig = .66;
        
        % stimulus timing stuff (in video frames)
        p.minTargSep = 5;
        p.minTargFrame = 6;
        p.maxTargFrame = 6;
        p.tempFreq = 6;
        p.targExpose = 2;
        p.respWindow = 60;
        
        
end

% convert all of the visual angles into pixels. Calibrated for the monitor
% on which the stimulus will be drawn
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
stim.nFlipsPerTrial = (length(stim.flicker)*2) + 2 + 1;


end

function stim = wrapper_deg2pix(stim, window)

stim.fixSizePix = deg2pix(stim.fixSizeDeg, window);
stim.stimSizePix = deg2pix(stim.stimSizeDeg, window);
stim.fixSizePix = deg2pix(stim.fixSizeDeg, window);
stim.offXPix = deg2pix(stim.offXDeg, window);
stim.offYPix = deg2pix(stim.offXDeg, window);
stim.stimSizePix = deg2pix(stim.stimSizeDeg, window);

end

