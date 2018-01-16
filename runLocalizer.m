function [ data, tInfo, expParams, input, qp, stim ] = ...
    runLocalizer( input, constants, window, responseHandler )
%208 TRs @ 1.5s/TR
%156 TRs @ 2s/TR  *** BUT, trial dur == 20s?

%{
Goal: localize voxels in V1 that respond well to grating stimuli at any
orientation.

Presents flickering checkerboard annulus for 10 seconds. 10 second ITI
where nothing but blank screen is present. To keep the participant engaged
in the task, they are to indicate when they notice the contrast of the
stimulus dim. The contrast dims 5 times on each trial, randomly throughout.

%}

expParams = setupExpParams(input.debugLevel, input.fMRI);

qp = setupQParams(expParams, input.fMRI);
fb = setupFeedback(input.fMRI);
data = setupDataTable(expParams, input);
keys = setupKeys(input.fMRI);
stim = setupStim(expParams, window, input);

tInfo = setupTInfo(expParams, stim.nFlipsPerTrial);

%%


img = makeGrating(p, stim.sf,...
    data.targOrient(trial), data.firstContrast(trial));
img_rev = makeGrating(p, stim.sf,...
    data.targOrient(trial), data.firstContrast(trial));
targ = makeGrating(p, stim.sf,...
    data.targOrient(trial), data.firstContrast(trial));
targ_rev = makeGrating(p, stim.sf,...
    data.targOrient(trial), data.firstContrast(trial));
gratings(1) = Screen('MakeTexture', window.pointer, img);
gratings(1) = Screen('MakeTexture', window.pointer, img_rev);
gratings(1) = Screen('MakeTexture', window.pointer, targ);
gratings(1) = Screen('MakeTexture', window.pointer, targ_rev);



%%
showPrompt(window, ['Attend to the contrast /n', ...
    'When it goes up, use your index finger./n' ,...
    'When it goes up, use your middle finger./n'], stim);

[triggerSent, exitFlag] = waitForStart(constants, keys, responseHandler);
switch exitFlag{1}
    case 'ESCAPE'
        return
end


for trial = 1:expParams.nTrials
    
    % record the trial onset time
    data.trialStart(trial) = GetSecs;
    
    if trial == 1
        firstFlipTime = triggerSent;
    else
        firstFlipTime = data.stimOff(trial-1);
    end
    [data.response(trial), data.rt(trial), ...
        data.stimOn(trial), data.stimOff(trial), ...
        tInfo(tInfo.trial==trial,:).vbl, tInfo(tInfo.trial==trial,:).missed, ...
        data.exitFlag(trial)] = ...
        elicitLocalizerResp(firstFlipTime, window, responseHandler, stim,...
        keys, expParams, data.roboRT(trial), data.answer(trial), constants);
    
    data.correct(trial) = analyzeResp(data.response(trial), data.answer(trial));
    giveFeedBack(data.correct(trial), fb);
    
    % start main rendering loop
    frmCnt=1; rCnt = 1;
    p.stimStart(trial) = GetSecs;   % start a clock to get the RT
    while frmCnt<=p.stimExpose
        if p.stimSequ(trial,frmCnt)
            Screen('DrawTexture', w, stims(p.stimSequ(trial,frmCnt)), [], p.dstRect, [], 1);
        end
        % redraw attention cue
        Screen('FillOval', w, p.fixColor, fixRect);
        Screen('DrawingFinished', w);
        Screen('Flip', w);
        p.fTime(trial,frmCnt)=GetSecs;
        
        % Read the keyboard, checking for response or 'escape'
        [resp, timeStamp] = checkForRespLoc([27,p.keys]);
        if resp==-1; ListenChar(0); return; end;
        if resp==p.keys
            p.resp(trial,rCnt) = frmCnt;
            p.rt(trial,rCnt) = GetSecs;
            rCnt=rCnt + 1;
        end
        
        frmCnt = frmCnt + 1;
    end %render loop
    
    % clear out screen
    Screen('FillOval', w, p.fixColor, fixRect);
    Screen('DrawingFinished', w);
    Screen('Flip', w);
    
    p.stimEnd(trial) = GetSecs;
    
    % compute accuracy on this trial
    p.actualRespFrm(trial).d = p.resp(trial,diff([0,p.resp(trial,:)])>1);
    for i=1:p.nTargs
        for ii=1:length(p.actualRespFrm(trial).d)
            if p.actualRespFrm(trial).d(ii)>p.targFrame(trial,i) && p.actualRespFrm(trial).d(ii)<=p.targFrame(trial,i)+p.respWindow
                p.correct = p.correct+1;
            end
        end
    end
    if length(p.actualRespFrm(trial).d)>p.nTargs
        p.guess = p.guess + (length(p.actualRespFrm(trial).d)-p.correct);
    end
    
    % wait the ITI
    while GetSecs<=cumTime+p.trialTime
        [resp, timeStamp] = checkForRespLoc([27,32]);
        if resp==-1; ListenChar(0); return; end;
    end
    cumTime = cumTime+p.trialTime;
    p.trialEnd(trial) = GetSecs;
    
end % end trial loop


end
