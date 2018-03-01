function stim = setupStim( expParams, window, input )

%{

stimuli are blurred annulus

note that we may still expect some edge-related activity along the middle
strip. that is, the middle strip is not blurred

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
% Henriksson 2008
stim.grating_center_deg = [1.7,4.7,6.3,9,19];  % eccentricities that were tested
% cpd => cycles per degree
% ordered from inntermost grating to outermost grating
stim.grating_freq_cpd = [1.2, 0.68, 0.46, 0.40, 0.18];

% from the center of fixation, how large should each aperture be?
stim.grating_radius_outer_deg = ...
    flip([stim.grating_center_deg(1:end-1) + diff(stim.grating_center_deg)/2, 40]);
stim.grating_radius_inner_deg = [stim.grating_radius_outer_deg(2:end), 0];

% convert all of the visual angles into pixels. Calibrated for the monitor
% on which the stimulus will be drawn
stim = wrapper_deg2pix(stim, window);

% number of pixels used to draw the stimulus
% Define prototypical gabor patch: si is
% half the wanted size. Later on, the 'DrawTextures' command will simply
% scale this patch up and down to draw individual patches of the different
% wanted sizes
stim.si = [2^10, 2^10, 2^10, 2^9, 2^9];

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

% ensure blending disabled in main window
stim.sourceFactor = 'GL_ONE';
stim.destinationFactor = 'GL_ZERO';
Screen('BlendFunction', window.pointer, stim.sourceFactor, stim.destinationFactor);

% stimulus parameters
stim.use_alpha = false; % dictates how alpha will be incorporated. false => modulate rgb values
stim.backgroundOffset = [];
stim.preContrastMultiplier = 0.5;

% smoothing method: cosine (0) or smoothstep (1)
stim.smooth_method = 1;

stim.sigma_pix_inner = input.sigma_scale * deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_freq_cpd);
stim.sigma_pix_outer = [stim.sigma_pix_inner(1), stim.sigma_pix_inner(1:end-1)];

% % Build a procedural gabor texture for a gabor with a support of tw x th
% pixels and ...
stim.tex = NaN([stim.n_gratings_per_side, 1]);
for grating = 1:stim.n_gratings_per_side
    stim.tex(grating) = CreateProceduralSmoothedAnnulusSineGrating(window.pointer, ...
        stim.tw(grating), stim.th(grating), stim.backgroundOffset, [stim.grating_radius_inner_deg(grating), stim.grating_radius_outer_deg(grating)], ...
        stim.preContrastMultiplier, [stim.sigma_pix_inner(grating), stim.sigma_pix_outer(grating)],...
        stim.use_alpha, stim.smooth_method);    
end

% Make a grey texture to cover the full window
stim.fullWindowTex_left = Screen('MakeTexture', window.pointer,...
    ones(window.winRect(4), window.winRect(3)) .* window.gray, [], [], 2);
stim.fullWindowTex_right = Screen('MakeTexture', window.pointer,...
    ones(window.winRect(4), window.winRect(3)) .* window.gray, [], [], 2);
Screen('BlendFunction', stim.fullWindowTex_left, 'GL_ONE', 'GL_ONE');
Screen('BlendFunction', stim.fullWindowTex_right, 'GL_ONE', 'GL_ONE');

% Preallocate array with destination rectangles:
% all gratings drawn to center of screen.
stim.dstRects = NaN(4, stim.n_gratings_per_side);
for grating = 1:stim.n_gratings_per_side
    texrect = Screen('Rect', stim.tex(grating));
    
    stim.dstRects(:,grating) = CenterRectOnPoint(texrect, ...
        window.xCenter, window.yCenter)';
end
stim.srcRect_left = [0; 0; window.xCenter - stim.strip_eccen_pix/2; window.winRect(4)];
stim.srcRect_right = [window.xCenter + stim.strip_eccen_pix/2; 0; window.winRect(3); window.winRect(4)];

% cue point coordinates
stim.fixRect = ...
    [[[-stim.fixSize_pix/2, stim.fixSize_pix/2];[0,0]],...
    [[0,0];[-stim.fixSize_pix/2, stim.fixSize_pix/2]]];


% stimulus parameters
switch input.experiment
    case 'contrast'
        % Liu, Cable, Gardner, 2017
        stim.contrast = [.2; .8];
        stim.reps_per_grating = 1;
        
    case 'localizer'
        stim.contrast = 1;
        stim.reps_per_grating = 2;
        
end

stim.n_gratings_per_side = stim.n_gratings_per_side * stim.reps_per_grating;
stim.n_gratings = stim.n_gratings_per_side * 2;
stim.dstRects = repmat(stim.dstRects, [1, stim.reps_per_grating]);

stim.background_img_filename = 'background.bmp';

%% initial flip to load + compile before it matters
contrast = 0;

n_stims = length(stim.tex);
Screen('DrawTextures', stim.fullWindowTex_left, stim.tex, [],...
    stim.dstRects(:,1:n_stims), 0, ...
    [], [], [], [], kPsychUseTextureMatrixForRotation, ...
    [ones(1,n_stims)*contrast; stim.grating_freq_cpp;...
    ones(1, n_stims)*contrast; zeros(1, n_stims)]);

Screen('DrawTextures', stim.fullWindowTex_right, stim.tex, [],...
    stim.dstRects(:,1:n_stims), 90, ...
    [], [], [], [], kPsychUseTextureMatrixForRotation, ...
    [ones(1,n_stims)*contrast; stim.grating_freq_cpp;...
    ones(1, n_stims)*contrast; zeros(1, n_stims)]);

% Batch-Draw the required parts of the mediating textures to onscreen
% window
Screen('DrawTextures', window.pointer, [stim.fullWindowTex_left, stim.fullWindowTex_right], ...
    [stim.srcRect_left, stim.srcRect_right], [stim.srcRect_left, stim.srcRect_right]);

% always draw central fixation cross
drawFixation(window, stim.fixRect, stim.fixLineSize,...
    1*contrast, input.experiment);

Screen('DrawingFinished', window.pointer);
Screen('Flip', window.pointer);

% imageArray = Screen('GetImage', window.pointer);
% imwrite(imageArray, stim.background_img_filename);

end

function stim = wrapper_deg2pix(stim, window)

stim.fixSize_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.fixSize_deg);
stim.grating_radius_outer_deg = deg2pix( window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_radius_outer_deg );
stim.grating_radius_inner_deg = deg2pix( window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_radius_inner_deg );
stim.grating_offset_eccen_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_center_deg);
stim.strip_eccen_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.strip_eccen_deg);

% cycles per degree is inverted from the others
stim.grating_freq_cpp = 1 ./ deg2pix(window.screen_w_cm, window.winRect(3), ...
    window.view_distance_cm, stim.grating_freq_cpd );

end

