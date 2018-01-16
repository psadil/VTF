function stim = setupStim( expParams, window, input )

%{
TODO:

- make fixation texture for drawing

%}

%%

% degree size of fixation
% values from Liu, Cable, Gardner, 2017
stim.fixSize_deg = 1;
stim.fixLineSize = 4;

% number of gabors to draw
stim.n_gratings = 2; % 2 -> one on left and right

% grating parameters
% values from Liu, Cable, Gardner, 2017
stim.grating_freq_cpd = .7; % cpd => cycles per degree
% stim.grating_aperture_deg = 10;
stim.grating_offset_eccen_deg = 8;
stim.orientations_deg = linspace(0,180-(180 / expParams.nOrientations), expParams.nOrientations);
% Spatial constant of the exponential "hull" (directly translates to size)
stim.sigma = 40;

% convert all of the visual angles into pixels. Calibrated for the monitor
% on which the stimulus will be drawn
stim = wrapper_deg2pix(stim, window);

% how often are phases of gabors updated (i.e., once every stim.update_phase_sec)
% note that in Liu et al., this is 0.2, but the phases update
% asyncronously. So, there is a new random phase ever 0.2/2 = 0.1 sec
stim.update_phase_sec = 0.1;
stim.n_phase_orientations = 16;

% number of pixels used to draw the stimulus
% Define prototypical gabor patch: si is
% half the wanted size. Later on, the 'DrawTextures' command will simply
% scale this patch up and down to draw individual patches of the different
% wanted sizes:
stim.si = 2^9;

% Size of support in pixels, derived from si:
stim.tw = 2*stim.si+1;
stim.th = 2*stim.si+1;

% % Build a procedural gabor texture for a gabor with a support of tw x th
% pixels and ...
% disableNorm := 1
% contrastPreMultiplicator := 0.5
stim.tex = CreateProceduralGabor(window.pointer, stim.tw, stim.th, [], [], 1, 0.5);
% stim.tex = CreateProceduralGabor(window.pointer, stim.tw, stim.th, 1);

% Preallocate array with destination rectangles:
stim.texrect = Screen('Rect', stim.tex);

stim.dstRects = zeros(4, stim.n_gratings);
stim.dstRects(:,1) = CenterRectOnPoint(stim.texrect, ...
    window.xCenter - stim.grating_offset_eccen_pix, window.yCenter)';
stim.dstRects(:,2) = CenterRectOnPoint(stim.texrect, ...
    window.xCenter + stim.grating_offset_eccen_pix, window.yCenter)';

switch input.experiment
    case 'contrast'
        % Liu, Cable, Gardner, 2017
        stim.contrast = [.2; .8]*100;
        
        % directions presented
        stim.targOrients = linspace(0,180-(180/expParams.nOrientations), expParams.nOrientations)*pi/180;
        
    case 'localizer'
        
        stim.contrast = 1;
        
end

% cue point coordinates
stim.fixRect = ...
    [[[-stim.fixSize_pix/2,stim.fixSize_pix/2]; ...
    [0,0]],...
    [[0,0];...
    [-stim.fixSize_pix/2,stim.fixSize_pix/2]]];

% flip sequence
stim.nFlipsPerSecOfTrial = ceil(1 / stim.update_phase_sec);
stim.nFlipsPerTrial = ceil(expParams.trial_stim_dur_sec * stim.nFlipsPerSecOfTrial);


% flip gabor once (initial flip has setup costs) and flip again to clear
% flipped with 0 contrast
Screen('DrawTexture', window.pointer, stim.tex, [], stim.dstRects(:,1), [], [], [], [], [],...
    kPsychDontDoRotation, [180, 0.05, 50, 0, 1, 0, 0, 0]);
Screen('Flip', window.pointer);
Screen('Flip', window.pointer);


end

function stim = wrapper_deg2pix(stim, window)

stim.fixSize_pix = deg2pix(stim.fixSize_deg, window);
% stim.grating_aperture_pix = deg2pix(stim.grating_aperture_deg, window);
stim.grating_offset_eccen_pix = deg2pix(stim.grating_offset_eccen_deg, window);
% stim.grating_freq_cpp = deg2pix(stim.grating_freq_cpd, window);
stim.grating_freq_cpp = 0.05;
end

