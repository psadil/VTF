function [] = showPrompt(window, prompt, start)

DrawFormattedText(window.pointer, prompt, 'center', 'center');

if start
    DrawFormattedText(window.pointer, '[Waiting for Start]', ...
        'center', window.winRect(4)*.8);
end
Screen('DrawingFinished',window.pointer);
Screen('Flip', window.pointer);

end

