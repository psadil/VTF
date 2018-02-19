function drawFixation(window, fix_xy, fix_width, color, experiment)

switch experiment
    case 'localizer_old'
        Screen('DrawLines', window.pointer, fix_xy, fix_width, color, [window.xCenter,window.yCenter]);
    otherwise
        % enable regular alpha blending for proper display of multiple lines
        [sourceFactorOld, destinationFactorOld] = ...
            Screen(window.pointer,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        Screen('DrawLines', window.pointer, fix_xy, fix_width, color, [window.xCenter,window.yCenter]);
        
        % reenable simpler blending for presentation of gabors
        Screen('BlendFunction', window.pointer, sourceFactorOld, destinationFactorOld);
                
end


end