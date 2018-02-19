function stim = setupStim( expParams, window, input )

%{
the mean optimal spatial frequencies are 1.2 cyc/-, 0.68 cyc/-, 0.46 cyc/-,
0.40 cyc/-, and 0.18 cyc/- corresponding to eccentricities 1.7-, 4.7-, 6.3-,9-,
and 19-

%}

%%

% degree size of fixation
% values from Liu, Cable, Gardner, 2017
stim.fixSize_deg = 1;
stim.fixLineSize = 2;

stim.strip_eccen_deg = 3;

% phases to present during trials
stim.orientations_deg = linspace(0,180-(180 / expParams.nOrientations), expParams.nOrientations);

% where to place the center of each grating
stim.grating_center_deg = [1.7,4.7,6.3,9,19];  % eccentricities that were tested

% from the center of fixation, how large should each aperture be?
stim.grating_aperture_from_fix_deg = ...
    flip([stim.grating_center_deg(1:end-1) + diff(stim.grating_center_deg)/2, Inf]);

% cpd => cycles per degree
% ordered from inntermost grating to outermost grating
stim.grating_freq_cpd = [1.2, 0.68, 0.46, 0.40, 0.18];

% convert all of the visual angles into pixels. Calibrated for the monitor
% on which the stimulus will be drawn
stim = wrapper_deg2pix(stim, window);

% number of pixels used to draw the stimulus
% Define prototypical gabor patch: si is
% half the wanted size. Later on, the 'DrawTextures' command will simply
% scale this patch up and down to draw individual patches of the different
% wanted sizes
stim.si = 2^10;

% % Size of support in pixels, derived from si:
stim.tw = 2*stim.si+1;
stim.th = 2*stim.si+1;

% number of gabors to draw
stim.n_gratings_per_side = 5;
stim.n_gratings = stim.n_gratings_per_side * 2; % 5 on each side

% how often are phases of gabors updated (i.e., once every stim.update_phase_sec)
% note that in Liu et al., this is 0.2, but the phases update
% asyncronously. So, there is a new random phase ever 0.2/2 = 0.1 sec
stim.update_phase_sec = 0.1;
stim.n_phase_orientations = 16;

% directions presented
stim.targOrients = linspace(0,180-(180/expParams.nOrientations), expParams.nOrientations)*pi/180;

% stimulus parameters
switch input.experiment
    case 'contrast'
        % ensure blending disabled
        stim.sourceFactor = 'GL_ONE';
        stim.destinationFactor = 'GL_ZERO';
        
        backgroundOffset = [.5, .5, .5, 1 ];
        preContrastMultiplier = 0.5;
        
    case 'localizer'
        % allow for additive blending
        stim.sourceFactor = 'GL_ONE';
        stim.destinationFactor = 'GL_ONE';
        
        backgroundOffset = [ ];
        preContrastMultiplier = 0.5;
        stim.strip = [window.xCenter - stim.strip_eccen_pix/2, 0,...
            window.xCenter + stim.strip_eccen_pix/2, window.winRect(4)];
end

% % Build a procedural gabor texture for a gabor with a support of tw x th
% pixels and ...
stim.tex = NaN([stim.n_gratings_per_side, 1]);
for grating = 1:stim.n_gratings_per_side
    stim.tex(grating) = CreateProceduralSineGrating(window.pointer, stim.tw, stim.th,...
        backgroundOffset, stim.grating_aperture_pix(grating), preContrastMultiplier);
end
Screen('BlendFunction', window.pointer, stim.sourceFactor, stim.destinationFactor);

% stimulus parameters
switch input.experiment
    case 'contrast'
        % Liu, Cable, Gardner, 2017
        stim.contrast = [.2; .8];
        stim.reps_per_grating = 1;
        % Make a grey texture to cover the full window
        stim.fullWindowTex_left = NaN([stim.reps_per_grating,1]);
        stim.fullWindowTex_right = NaN([stim.reps_per_grating,1]);
        for bkgrd = 1:stim.reps_per_grating
            stim.fullWindowTex_left(bkgrd) = Screen('MakeTexture', window.pointer,...
                ones(window.winRect(4), window.winRect(3)) .* window.gray);
            stim.fullWindowTex_right(bkgrd) = Screen('MakeTexture', window.pointer,...
                ones(window.winRect(4), window.winRect(3)) .* window.gray);
            Screen('BlendFunction', stim.fullWindowTex_right(bkgrd), 'GL_ONE', 'GL_ZERO');
            Screen('BlendFunction', stim.fullWindowTex_right(bkgrd), 'GL_ONE', 'GL_ZERO');

        end

    case 'localizer'
        stim.contrast = 1;
        stim.reps_per_grating = 1;
        
        stim.fullWindowTex_left = NaN([stim.reps_per_grating,1]);
        stim.fullWindowTex_right = NaN([stim.reps_per_grating,1]);
end

% Preallocate array with destination rectangles:
% all gratings drawn to center of screen.
stim.texrect = Screen('Rect', stim.tex(1));

stim.dstRects = CenterRectOnPoint(stim.texrect, ...
        window.xCenter, window.yCenter)';
stim.srcRect_left = [0; 0; window.xCenter - stim.strip_eccen_pix/2; window.winRect(4)];
stim.srcRect_right = [window.xCenter + stim.strip_eccen_pix/2; 0; window.winRect(3); window.winRect(4)];

% cue point coordinates
stim.fixRect = ...
    [[[-stim.fixSize_pix/2, stim.fixSize_pix/2];[0,0]],...
    [[0,0];[-stim.fixSize_pix/2, stim.fixSize_pix/2]]];

end

function stim = wrapper_deg2pix(stim, window)

stim.fixSize_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.fixSize_deg);
stim.grating_aperture_pix = deg2pix( window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_aperture_from_fix_deg );
stim.grating_offset_eccen_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_center_deg);
stim.strip_eccen_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.strip_eccen_deg);

% cycles per degree is inverted from the others
stim.grating_freq_cpp = 1 ./ deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_freq_cpd );

end

