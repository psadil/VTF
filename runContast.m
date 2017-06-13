function [ data, tInfo, expParams, input, qp, stim ] = ...
    runContast( input, constants, window, responseHandler )

expParams = setupExpParams(input.debugLevel, input.fMRI, input.experiment);

qp = setupQParams(expParams, input.fMRI);
fb = setupFeedback(input.fMRI);
data = setupDataTable(expParams, input);
keys = setupKeys(input.fMRI);
stim = setupStim(expParams, window, input);

tInfo = setupTInfo(expParams, stim.nFlipsPerTrial);

%%
showPrompt(window, ['Attend to the contrast /n', ...
    'When it goes up, use your index finger./n' ,...
    'When it goes up, use your middle finger./n'], stim);

[triggerSent, exitFlag] = waitForStart(constants, keys, responseHandler);
switch exitFlag{1}
    case 'ESCAPE'
        return
end

% these are useful as comparisons against what actually happened
data.tStart_expected = ...
    (triggerSent:expParams.trialDur: ...
    (triggerSent + (expParams.trialDur*(expParams.nTrials-1))))';
data.tEnd_expected = ...
    (triggerSent + expParams.trialDur:expParams.trialDur: ...
    (triggerSent + (expParams.trialDur*(expParams.nTrials))))';

for trial = 1:expParams.nTrials
    
    % record the trial onset time
    data.trialStart(trial) = GetSecs;
    
    % decide on contrast value for this trial.
    % First contrast is always set
    % Second contrast depends on participant's
    % NOTE: second contrast will always be 0 on null trials
    switch data.tType(trial)
        case 0
            data.firstContrast(trial) = 0;
            data.secondContrast(trial) = 0;
        otherwise
            data.firstContrast(trial) = stim.contrast(data.tType(trial));
            data.secondContrast(trial) = ...
                data.firstContrast(trial) + ...
                (qp.cdThresh(data.tType(trial)) * qp.cShift(trial));
    end
    img1 = makeGrating(p, stim.sf,...
        data.targOrient(trial), data.firstContrast(trial));
    img2 = makeGrating(p, stim.sf,...
        data.targOrient(trial), data.secondContrast(trial));
    stim.tex1 = Screen('MakeTexture', window.pointer, img1);
    stim.tex2 = Screen('MakeTexture', window.pointer, img2);
    
    % keep track of the values on this trial by filling in
    % staircases.
    data.contStair(data.tType(trial), trial) = qp.cdThresh(data.tType(trial));
    
    if trial == 1
        firstFlipTime = triggerSent;
    else
        firstFlipTime = data.stimOff(trial-1);
    end
    [data.response(trial), data.rt(trial), ...
        data.stimOn(trial), data.stimOff(trial), ...
        tInfo(tInfo.trial==trial,:).vbl, tInfo(tInfo.trial==trial,:).missed, ...
        data.exitFlag(trial)] = ...
        elicitContrastResp(firstFlipTime, window, responseHandler, stim,...
        keys, expParams, data.roboRT(trial), data.answer(trial), constants);
    Screen('Close', [stim.tex1, stim.tex2]);
    
    data.correct(trial) = analyzeResp(data.response(trial), data.answer(trial));
    giveFeedBack(data.correct(trial), fb);
    
    qp = updateQ(data.correct(trial), data.tType(trial), qp);
    
    data.trialEnd(trial) = GetSecs;
end  % end of this trial
constants.endStimTime = GetSecs;


% wait post dur
if input.fMRI
    while GetSecs <= constants.startExp + expParams.scanDur
        if checkForResp(p.escape); ListenChar(0); return; end;
    end
end


end
