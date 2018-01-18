function stim = setupStim( expParams, window, input )

%{
TODO:


%}

%%

% degree size of fixation
% values from Liu, Cable, Gardner, 2017
stim.fixSize_deg = 1;
stim.fixLineSize = 2;

% values from Liu, Cable, Gardner, 2017
% distance between the two gabors (so, offset from center is half this)
stim.grating_offset_eccen_deg = 16; 

% phases to present during trials
stim.orientations_deg = linspace(0,180-(180 / expParams.nOrientations), expParams.nOrientations);

% size of circular aperture masking the image
stim.grating_aperture_deg = 10;

% cpd => cycles per degree
stim.grating_freq_cpd = .7; 

% convert all of the visual angles into pixels. Calibrated for the monitor
% on which the stimulus will be drawn
stim = wrapper_deg2pix(stim, window);

% number of pixels used to draw the stimulus
% Define prototypical gabor patch: si is
% half the wanted size. Later on, the 'DrawTextures' command will simply
% scale this patch up and down to draw individual patches of the different
% wanted sizes
stim.si = 2^9;

% Size of support in pixels, derived from si:
stim.tw = 2*stim.si+1;
stim.th = 2*stim.si+1;

% number of gabors to draw
stim.n_gratings = 2; % 2 -> one on left and right

% stimulus parameters
switch input.experiment
    case 'contrast'
        
        % enable blending (needed so that neighboring textures show proper grey
        % background)
        Screen('BlendFunction', window.pointer, GL_ONE, GL_ONE);
        
        % how often are phases of gabors updated (i.e., once every stim.update_phase_sec)
        % note that in Liu et al., this is 0.2, but the phases update
        % asyncronously. So, there is a new random phase ever 0.2/2 = 0.1 sec
        stim.update_phase_sec = 0.1;
        stim.n_phase_orientations = 16;
        
        % % Build a procedural gabor texture for a gabor with a support of tw x th
        % pixels and ...
        backgroundOffset = []; % no offset for proper alpha
        preContrastMultiplier = 0.5;
        stim.tex = CreateProceduralSineGrating(window.pointer, stim.tw, stim.th,...
            backgroundOffset, stim.grating_aperture_pix, preContrastMultiplier);
        
        % Liu, Cable, Gardner, 2017
        stim.contrast = [.2; .8];
        
        % directions presented
        stim.targOrients = linspace(0,180-(180/expParams.nOrientations), expParams.nOrientations)*pi/180;
        
    case 'localizer'
        % number of gabors to draw
        stim.n_gratings = stim.n_gratings * 2; % two on each left and right
        
        % enable blending (needed so that neighboring textures show proper grey
        % background)
        Screen('BlendFunction', window.pointer, GL_ONE, GL_ONE);
        
        % how often are phases of gabors updated (i.e., once every stim.update_phase_sec)
        % note that in Liu et al., this is 0.2, but the phases update
        % asyncronously. So, there is a new random phase ever 0.2/2 = 0.1 sec
        stim.update_phase_sec = 0.1;
        stim.n_phase_orientations = 16;
        
        % % Build a procedural gabor texture for a gabor with a support of tw x th
        % pixels and ...
        backgroundOffset = []; % no offset for proper alpha
        preContrastMultiplier = 0.5;
        stim.tex = CreateProceduralSineGrating(window.pointer, stim.tw, stim.th,...
            backgroundOffset, stim.grating_aperture_pix, preContrastMultiplier);
        
        stim.contrast = 1;
        
        % directions presented
        stim.targOrients = linspace(0,180-(180/expParams.nOrientations), expParams.nOrientations)*pi/180;
        
    case 'localizer_old'
        % Set up alpha-blending for smooth (anti-aliased) lines
        Screen('BlendFunction', window.pointer, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        
        stim.contrast = 10;
        
        % double numberof black and white squares to draw
        stim.grating_freq_cycles = ...
            stim.grating_aperture_deg * stim.grating_freq_cpd;
        
        %make matrices x and y with meshgrid to hold pixel locations in terms
        %of visual angle.
        tmpX  = linspace(-stim.grating_aperture_pix,stim.grating_aperture_pix,...
            stim.grating_aperture_pix*2);
        [x, y] = meshgrid(tmpX);
        
        %make a checkerboard image containing -1's and 1's.
        chex = sign(sin(2*pi*stim.grating_freq_cpd*x) .*...
            sin(2*pi*stim.grating_freq_cpd*y));
        circle = x.^2+y.^2 <= (stim.grating_aperture_pix)^2;
        
        % here, we rely on alpha blending for smooth aperture masking
        img1 = cat(3,chex,circle);
        % make contrast reversal image
        img2 = cat(3,-1*chex,circle);
        
        stim.tex1 = Screen('MakeTexture', window.pointer, img1);
        stim.tex2 = Screen('MakeTexture', window.pointer, img1);
        
        % Set the colors of each of our squares
        byColors = repmat(eye(2), stim.grating_freq_cycles/2, stim.grating_freq_cycles/2);
        bwColors = [repmat(byColors(:), [3,1]); circle];
        
        % Make our rectangle coordinates
        allRects = nan(4, 3);
        for i = 1:numSquares
            allRects(:, i) = CenterRectOnPointd(baseRect,...
                xPos(i), yPos(i));
        end
        
        stim.texrect = [0, 0, max(xPos), max(yPos)];
        
        stim.contrast = 1;
        
end

% Preallocate array with destination rectangles:
stim.texrect = Screen('Rect', stim.tex);

stim.dstRects = zeros(4, stim.n_gratings);
for rect = 1:stim.n_gratings
    if mod(rect,2)
        offset = - stim.grating_offset_eccen_pix;
    else
        offset = stim.grating_offset_eccen_pix;
    end
    stim.dstRects(:,rect) = CenterRectOnPoint(stim.texrect, ...
        window.xCenter + offset , window.yCenter)';
end

% cue point coordinates
stim.fixRect = ...
    [[[-stim.fixSize_pix/2, stim.fixSize_pix/2];[0,0]],...
    [[0,0];[-stim.fixSize_pix/2, stim.fixSize_pix/2]]];

% flip sequence
stim.nFlipsPerSecOfTrial = ceil(1 / stim.update_phase_sec);

% note that final flip is an ITI start
stim.nFlipsPerTrial = ceil(expParams.trial_stim_dur_sec * stim.nFlipsPerSecOfTrial);

% flip gabor once (initial flip has setup costs) and flip again to clear
contrast_tmp = max(stim.contrast)*0 ;
angle = [0,0,90,90];
freq = stim.grating_freq_cpp;
Screen('DrawTextures', window.pointer, stim.tex, [], stim.dstRects, angle(1:stim.n_gratings), [], [], [], [],...
    [], [180, freq, contrast_tmp, 0]');
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

