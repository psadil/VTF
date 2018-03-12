function [window, stim] = SineGratingSmoothAnnulusDemo(varargin)


%% collect input
% use the inputParser class to deal with arguments
ip = inputParser;
addParameter(ip, 'duration_sec', 2, @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'debuglevel', 0, @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'contrast', 1,  @(x) isnumeric(x) && x >= 0 && x <= 1);
addParameter(ip, 'angle', 90,  @(x) isnumeric(x) && x >= 0 && x <= 180);
addParameter(ip, 'sigma_scale', 1,  @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'mid_strip_deg', 3,  @(x) isnumeric(x) && x >= 0);
addParameter(ip, 'save_stim', false,  @islogical);
addParameter(ip, 'orient_method', 'offscreen',  @(x) sum(strcmp(x, {'offscreen', 'onscreen'}))==1);
parse(ip,varargin{:});
input = ip.Results;

%% setup, Window

try
    PsychDefaultSetup(2);
    ListenChar(-1);
    HideCursor;
    
    window.screen_w_cm = 35;
    window.screen_h_cm = 19.6;
    window.view_distance_cm = 137;
    
    % Choose a monitor to display on
    window.screenNumber = max(Screen('Screens'));
    
    window.gray = GrayIndex(window.screenNumber);
    
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'NormalizedHighresColorRange', 1);
    
    % need 32Bit for proper alpha blending, which only barely happens here (and
    % maybe not at all). Though, this asks for the higher precision nicely, and
    % defaults to 16 if not possible
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
    PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');
    switch input.debuglevel
        case 1
            Screen('Preference', 'SkipSyncTests', 2);
            [window.pointer, window.winRect] = ...
                PsychImaging('OpenWindow', window.screenNumber, window.gray);
        case 0
            [window.pointer, window.winRect] = ...
                PsychImaging('OpenWindow', window.screenNumber, window.gray);
    end
    % ensure blending disabled in main window
    window.sourceFactor = 'GL_ONE';
    window.destinationFactor = 'GL_ZERO';
    Screen('BlendFunction', window.pointer, window.sourceFactor, window.destinationFactor);
    
    % Make sure the GLSL shading language is supported:
    AssertGLSL;
    
    % define some landmark locations to be used throughout
    [window.xCenter, window.yCenter] = RectCenter(window.winRect);
    
    
    %% setup, stimuli
    
    stim.mid_strip_pix = deg2pix(window.screen_w_cm, window.winRect(3), ...
        window.view_distance_cm, input.mid_strip_deg );
    
    % where to place the center of each grating
    stim.grating_center_deg = [1.7, 4.7, 6.3, 9, 19];
    
    % cpd => cycles per degree
    % ordered from inntermost grating to outermost grating
    stim.grating_freq_cpd = [1.2, 0.68, 0.46, 0.40, 0.18];
    
    % cycles per degree is inverted from the others
    stim.grating_freq_cpp = 1 ./ deg2pix(window.screen_w_cm, window.winRect(3), ...
        window.view_distance_cm, stim.grating_freq_cpd );
    
    % from the center of fixation, how large should each aperture be?
    stim.grating_radius_outer_deg = ...
        flip([stim.grating_center_deg(1:end-1) + diff(stim.grating_center_deg)/2, 40]);
    stim.grating_radius_inner_deg = [stim.grating_radius_outer_deg(2:end), 0];
    
    stim.grating_radius_outer_pix = deg2pix( window.screen_w_cm, window.winRect(3), ...
        window.view_distance_cm, stim.grating_radius_outer_deg );
    stim.grating_radius_inner_pix = deg2pix( window.screen_w_cm, window.winRect(3), ...
        window.view_distance_cm, stim.grating_radius_inner_deg );
    
    % number of pixels used to draw the stimulus
    % Define prototypical gabor patch: si is
    % half the wanted size. Later on, the 'DrawTextures' command will simply
    % scale this patch up and down to draw individual patches of the different
    % wanted sizes
    stim.si = [2^10, 2^10, 2^10, 2^9, 2^8];
    
    % % Size of support in pixels, derived from si:
    stim.tw = 2*stim.si+1;
    stim.th = 2*stim.si+1;
    
    % number of gabors to draw
    stim.n_gratings_per_side = 5;
    stim.n_gratings = stim.n_gratings_per_side * 2; % 5 on each side
    
    stim.use_alpha = false; % dictates how alpha will be incorporated. false => modulate rgb values
    stim.backgroundOffset = [];
    stim.preContrastMultiplier = 0.5;
    
    stim.sigma_pix_inner = input.sigma_scale * deg2pix(window.screen_w_cm, window.winRect(3), ...
        window.view_distance_cm, stim.grating_freq_cpd);
    stim.sigma_pix_outer = [stim.sigma_pix_inner(1), stim.sigma_pix_inner(1:end-1)];
    
    % smoothing method: cosine (0) or smoothstep (1)
    stim.smooth_method = 1;
    
    % % Build a procedural gabor texture for a gabor with a support of tw x th
    % pixels and ...
    stim.tex = NaN([stim.n_gratings_per_side, 1]);
    for grating = 1:stim.n_gratings_per_side
        stim.tex(grating) = CreateProceduralSmoothedAnnulusSineGrating(window.pointer, ...
            stim.tw(grating), stim.th(grating), stim.backgroundOffset, [stim.grating_radius_inner_pix(grating), stim.grating_radius_outer_pix(grating)], ...
            stim.preContrastMultiplier, [stim.sigma_pix_inner(grating), stim.sigma_pix_outer(grating)],...
            stim.use_alpha, stim.smooth_method);
    end
    
    % Make a grey texture to cover the full window
    stim.fullWindowTex_left = Screen('MakeTexture', window.pointer,...
        ones(window.winRect(4), window.winRect(3)) .* window.gray, [], [], 2);
    stim.fullWindowTex_right = Screen('MakeTexture', window.pointer,...
        ones(window.winRect(4), window.winRect(3)) .* window.gray, [], [], 2);
    
    % additive blending for these offscreen windows
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
    
    % after gratings have been drawn to the offscreen windows and rotated,
    % we'll only display srcRect part of the offscreen windows
    srcRect_left = [0; 0; window.xCenter - stim.mid_strip_pix/2; window.winRect(4)];
    srcRect_right = [window.xCenter + stim.mid_strip_pix/2; 0; window.winRect(3); window.winRect(4)];
    
    stim.srcRects = [srcRect_left, srcRect_right];
    
    %% Draw time
    
    switch input.orient_method
        case 'offscreen'
            % draw
            Screen('DrawTextures', stim.fullWindowTex_left, stim.tex, [],...
                stim.dstRects, input.angle, ...
                [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                [zeros(1, stim.n_gratings_per_side); stim.grating_freq_cpp;...
                ones(1,stim.n_gratings_per_side)*input.contrast; zeros(1, stim.n_gratings_per_side)]);
            
            Screen('DrawTextures', stim.fullWindowTex_right, stim.tex, [],...
                stim.dstRects, input.angle, ...
                [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                [zeros(1, stim.n_gratings_per_side); stim.grating_freq_cpp;...
                ones(1,stim.n_gratings_per_side)*input.contrast; zeros(1, stim.n_gratings_per_side)]);
            
            % Batch-Draw the required parts of the mediating textures to onscreen
            % window
            Screen('DrawTextures', window.pointer, [stim.fullWindowTex_left, stim.fullWindowTex_right], ...
                stim.srcRects, stim.srcRects);
            
        case 'onscreen'
            Screen('DrawTextures', window.pointer, stim.tex, stim.srcRects,...
                stim.srcRects, input.angle, ...
                [], [], [], [], kPsychUseTextureMatrixForRotation, ...
                [zeros(1, stim.n_gratings_per_side); stim.grating_freq_cpp;...
                ones(1,stim.n_gratings_per_side)*input.contrast; zeros(1, stim.n_gratings_per_side)]);
            
    end
    Screen('Flip', window.pointer);
    
    if input.save_stim
        imageArray = Screen('GetImage', window.pointer);
        imwrite(imageArray, [input.orient_method, '.png']);
    end
    
    WaitSecs(input.duration_sec)
    
    windowcleanup();
catch msg
    windowcleanup;
    rethrow(msg);
end

end


function pixels = deg2pix(size_cm, size_pix, view_distance_cm, desired_degrees )

max_degrees = rad2deg(2 * atan( size_cm / view_distance_cm ));
pixels_per_degree = size_pix / max_degrees;
pixels = pixels_per_degree * desired_degrees;

end

function windowcleanup
ListenChar(0);
Priority(0);
sca;

end
