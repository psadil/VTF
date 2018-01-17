function stim = setupStim( expParams, window, input )

%{
TODO:


%}

%%

% degree size of fixation
% values from Liu, Cable, Gardner, 2017
stim.fixSize_deg = 1;
stim.fixLineSize = 2;

% number of gabors to draw
stim.n_gratings = 2; % 2 -> one on left and right

% grating parameters
% values from Liu, Cable, Gardner, 2017
stim.grating_freq_cpd = .7; % cpd => cycles per degree
stim.grating_offset_eccen_deg = 16;
stim.orientations_deg = linspace(0,180-(180 / expParams.nOrientations), expParams.nOrientations);
stim.grating_aperture_deg = 10;

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
% wanted sizes: (also, radius will change what happens)
stim.si = 2^9;

% Size of support in pixels, derived from si:
stim.tw = 2*stim.si+1;
stim.th = 2*stim.si+1;

% % Build a procedural gabor texture for a gabor with a support of tw x th
% pixels and ...
backgroundOffset = []; % no offset for proper alpha
preContrastMultiplier = 0.5;
stim.tex = CreateProceduralSineGrating(window.pointer, stim.tw, stim.th,...
    backgroundOffset, stim.grating_aperture_pix, preContrastMultiplier);

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
        stim.contrast = [.2; .8];
        
        % directions presented
        stim.targOrients = linspace(0,180-(180/expParams.nOrientations), expParams.nOrientations)*pi/180;
        
    case 'localizer'
        
        stim.contrast = 1;
        
end

% cue point coordinates
stim.fixRect = ...
    [[[-stim.fixSize_pix/2, stim.fixSize_pix/2];[0,0]],...
    [[0,0];[-stim.fixSize_pix/2, stim.fixSize_pix/2]]];

% flip sequence
stim.nFlipsPerSecOfTrial = ceil(1 / stim.update_phase_sec);
stim.nFlipsPerTrial = ceil(expParams.trial_stim_dur_sec * stim.nFlipsPerSecOfTrial);


% flip gabor once (initial flip has setup costs) and flip again to clear
contrast_tmp = max(stim.contrast) * 0;
angle = 45;
freq = stim.grating_freq_cpp;
Screen('DrawTexture', window.pointer, stim.tex, [], stim.dstRects(:,1), angle, [], [], [], [],...
    [], [180, freq, contrast_tmp, 0]);
Screen('Flip', window.pointer);
Screen('Flip', window.pointer);


end

function stim = wrapper_deg2pix(stim, window)

stim.fixSize_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.fixSize_deg);
stim.grating_aperture_pix = deg2pix( window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_aperture_deg );
stim.grating_offset_eccen_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_offset_eccen_deg);

% cycles per degree is inverted from the others
stim.grating_freq_cpp = 1/deg2pix( window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_freq_cpd );

end

