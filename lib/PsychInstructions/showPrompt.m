function [] = ...
    showPrompt(window, prompt, stim)

Screen('Flip', window.pointer);

DrawFormattedText(window.pointer, prompt,...
    'center', 'center');
Screen('FillOval', window.pointer, stim.fixColor(3,:), stim.fixRect);
DrawFormattedText(window.pointer, '[Waiting for Start]', ...
    'center', window.winRect(4)*.8);

Screen('DrawingFinished',window.pointer);
Screen('Flip', window.pointer);

end

