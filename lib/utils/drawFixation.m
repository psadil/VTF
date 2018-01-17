function drawFixation(window, fix_xy, fix_width, color)

% enable regular alpha blending for proper display of multiple lines
Screen(window.pointer,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

Screen('DrawLines', window.pointer, fix_xy, fix_width, color, [window.xCenter,window.yCenter]);

% reenable simpler blending for presentation of gabors
Screen('BlendFunction', window.pointer, GL_ONE, GL_ONE);

end