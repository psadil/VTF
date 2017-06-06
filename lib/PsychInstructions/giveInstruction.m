function vbl = giveInstruction(window, keys, responseHandler, constants, expt, expParams)


%%
Screen('DrawingFinished', w);
Screen('Flip', w);


vbl = showPromptAndWaitForResp(window, 'Attend Contrast (Lower/Higher)',...
    keys,constants,responseHandler);
        



end