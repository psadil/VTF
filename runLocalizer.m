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



% destination rects for stim and fixation point
fixRect = [(p.xCenter  - p.fixSizePix),(p.yCenter - p.fixSizePix),(p.xCenter  + p.fixSizePix), (p.yCenter + p.fixSizePix)];
p.dstRect = [p.xCenter-p.stimSizePix, p.yCenter-p.stimSizePix, p.xCenter+p.stimSizePix, p.yCenter+p.stimSizePix];


% allocate some arrays for storing subject response
p.fTime = zeros(p.nTrials, p.stimExpose);
p.resp =      zeros(p.nTrials, p.nTargs);        % store the response
p.correct =   0;
p.guess = 0;
p.rt =        nan(p.nTrials, p.nTargs);        % store the response
p.trialStart =  zeros(1, p.nTrials);
p.trialEnd   =  zeros(1, p.nTrials);
p.stimEnd   =  zeros(1, p.nTrials);
p.stimStart =   zeros(1, p.nTrials);
p.targetContrast =  nan(1, p.nTrials);
p.stimSequ   =  zeros(p.nTrials, p.stimExpose);
p.targetContrast =  nan(1, p.nTrials);
p.targFrame = zeros(p.nTrials, p.nTargs);
p.targOnTime = zeros(p.nTrials, p.nTargs);
p.targMaxRespTime = zeros(p.nTrials, p.nTargs);

% generate a distribution for choosing the target time
nStims = (p.stimExpose/p.RefreshRate)*((p.RefreshRate/p.tempFreq)/2);
p.targX = p.minTargFrame:p.minTargSep:nStims-p.maxTargFrame;
for ii=1:p.nTrials
    tmp = randperm(length(p.targX));
    p.targFrame(ii,:) = sort(p.targX(tmp(1:p.nTargs)))*(p.tempFreq*2)-(p.tempFreq*2)+1;
    p.targOnTime(ii,:) = p.targFrame(ii,:).*(1/p.RefreshRate);
    p.targMaxRespTime(ii,:) = (p.targFrame(ii,:).*(1/p.RefreshRate))+p.respWindow;
end

% compute the ramp for the gabor, then make the target sequence for
% this trial
p.targetContrast = p.cThresh1;

%make matrices x and y with meshgrid to hold pixel locations in terms
%of visual angle.
tmpX  = linspace(-p.stimSizePix,p.stimSizePix,p.stimSizePix*2);
[x,y] = meshgrid(tmpX);

%make a checkerboard image containing -1's and 1's.
chex = sign(sin(2*pi*p.sf*x).*sin(2*pi*p.sf*y));
circle = x.^2+y.^2<=(p.stimSizePix)^2;
id  = x.^2 + y.^2 <= p.innerRPix^2;

% first make the standard checkerboards
img1 = chex.*circle;
img2 = -1*img1; % contrast reversal

img1(id) = 0;
img2(id) = 0;

tmpImg = p.LUT(round(((1*img1)+1)*127)+1);
stims(1)=Screen('MakeTexture', w, tmpImg);

tmpImg = p.LUT(round(((1*img2)+1)*127)+1);
stims(2)=Screen('MakeTexture', w, tmpImg); % other checkerboard

% then make the targets
tmpImg = p.LUT(round((((1-p.targetContrast)*img1)+1)*127)+1);
stims(3)=Screen('MakeTexture', w, tmpImg);

tmpImg = p.LUT(round((((1-p.targetContrast)*img2)+1)*127)+1);
stims(4)=Screen('MakeTexture', w, tmpImg); % other checkerboard

% pick the stimulus sequence for every trial (the exact grating to be shown)
for i=1:p.nTrials
    p.flickerSequ=[];
    for ii=1:(p.stimExpose/(p.tempFreq*2))
        % when picking the stim sequence, randomly alternate the phase
        % to attenuate apparent motion
        p.flickerSequ = [p.flickerSequ, [repmat(1,1,p.tempFreq),repmat(2,1,p.tempFreq)]];            % pick a stim sequence
    end
    
    p.stimSequ(i,:)=p.flickerSequ;
    
    % mark the tarket spots with low contrast stims
    for j=1:p.nTargs
        p.stimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+(p.tempFreq)-1)=p.stimSequ(i,p.targFrame(i,j):p.targFrame(i,j)+(p.tempFreq)-1)+2;
    end
end

%%
showPrompt(window, ['Attend to the contrast /n', ...
    'When it goes up, use your index finger./n' ,...
    'When it goes up, use your middle finger./n'], stim);

[triggerSent, exitFlag] = waitForStart(constants, keys, responseHandler);
switch exitFlag{1}
    case 'ESCAPE'
        return
end

%%

% here is the start of the trial loop
for t=1:p.nTrials
    % start a rendering loop to put up a stimulus
    p.trialStart(t) = GetSecs;   % start a clock to get the RT
    % start main rendering loop
    frmCnt=1; rCnt = 1;
    p.stimStart(t) = GetSecs;   % start a clock to get the RT
    while frmCnt<=p.stimExpose
        if p.stimSequ(t,frmCnt)
            Screen('DrawTexture', w, stims(p.stimSequ(t,frmCnt)), [], p.dstRect, [], 1);
        end
        % redraw attention cue
        Screen('FillOval', w, p.fixColor, fixRect);
        Screen('DrawingFinished', w);
        Screen('Flip', w);
        p.fTime(t,frmCnt)=GetSecs;
        
        % Read the keyboard, checking for response or 'escape'
        [resp, timeStamp] = checkForRespLoc([27,p.keys]);
        if resp==-1; ListenChar(0); return; end;
        if resp==p.keys
            p.resp(t,rCnt) = frmCnt;
            p.rt(t,rCnt) = GetSecs;
            rCnt=rCnt + 1;
        end
        
        frmCnt = frmCnt + 1;
    end %render loop
    
    % clear out screen
    Screen('FillOval', w, p.fixColor, fixRect);
    Screen('DrawingFinished', w);
    Screen('Flip', w);
    
    p.stimEnd(t) = GetSecs;
    
    % compute accuracy on this trial
    p.actualRespFrm(t).d = p.resp(t,diff([0,p.resp(t,:)])>1);
    for i=1:p.nTargs
        for ii=1:length(p.actualRespFrm(t).d)
            if p.actualRespFrm(t).d(ii)>p.targFrame(t,i) && p.actualRespFrm(t).d(ii)<=p.targFrame(t,i)+p.respWindow
                p.correct = p.correct+1;
            end
        end
    end
    if length(p.actualRespFrm(t).d)>p.nTargs
        p.guess = p.guess + (length(p.actualRespFrm(t).d)-p.correct);
    end
    
    % wait the ITI
    while GetSecs<=cumTime+p.trialTime
        [resp, timeStamp] = checkForRespLoc([27,32]);
        if resp==-1; ListenChar(0); return; end;
    end
    cumTime = cumTime+p.trialTime;
    p.trialEnd(t) = GetSecs;
    
end % end trial loop


end
