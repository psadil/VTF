function drawFixation(window, fix_xy, fix_width, color)

Screen('DrawLines', window.pointer, fix_xy, fix_width, color, [window.xCenter,window.yCenter]);

end