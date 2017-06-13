function localizer
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

%%
%get subject info
prompt = {'Subject Name', 'Scan Number', 'Contrast', 'Random Seed','fMRI(1=Yes)'};
%grab a random number and seed the generator (include this as a gui field in case want to repeat and exact sequence)
s = round(sum(100*clock));
%fill in some stock answers to the gui input boxes
defAns = {'RR','','.3',num2str(s),'1'};
box = inputdlg(prompt,'Enter Subject Information...', 1, defAns);
if length(box)==length(defAns)      %simple check for enough input, otherwise bail out
    p.subName=char(box{1});p.scanNum=str2num(box{2});p.cThresh1=str2num(box{3});p.rndSeed=str2num(box{4});
    p.fMRI=str2num(box{5});
    rand('state',p.rndSeed);  %actually seed the random number generator
else    %if cancel button or not enough input, then just bail
    return
end
ListenChar(2);

%--------------------begin user define parameters----------------------------%
p.fullScreen = 1;                     % if 1 then the display will be in a small window, use this for debugging.

% monitor stuff
% if ~p.fMRI
p.RefreshRate = 60;               % refresh rate - not yet used xx
% else
%     p.RefreshRate = 120;
% end


% total stim exposure duration
p.nTrials = 15;                     % number of trials (must be evenly divisible by three and by cueValidity, see below)

% viewing distance and screen width, in CM...used to convert degrees visual
% angle to pixel units later on for drawing stuff
if p.fMRI
    p.screenWidthCM = 80;
    p.vDistCM = 137;
else
    p.screenWidthCM = 34.29;
    p.vDistCM = 50.8;
end

%stimulus colors
p.bckGrnd   = .5;
p.fontColor = 1;

% for check stims
p.sf = 1;                       %cycles/deg for checkerboards
p.tf = 8;                       %temporal frequency (Hz)

%stimulus properties
p.stimSizeDeg = 7.5;    % radius
% p.n = 512;          % pixels
p.n = 2048;
[p.x,p.y] = meshgrid(linspace(-1,1,p.n));
p.sf = 5;           % cycles/image
p.r = .25;          % radius of inner blank circle - fraction of total stim size
p.xc = 0;           % center of gaussian window
p.yc = 0;
p.sig = .66;        % 1/e half width of gaussian
p.innerRDeg = 2;

%fixation point and cue properties
p.fixColor = [255, 255, 255];
p.fixSizeDeg = .25;                  % length of the lines

% stimulus timing stuff (in video frames)
p.stimExpose = 600;
p.nTargs = 5;
p.minTargSep = 5;
p.minTargFrame = 6;
p.maxTargFrame = 6;
p.tempFreq = 6;
p.targExpose = 2;
p.ITI = 10;
p.respWindow = 60;
p.endFix = 12;
p.stimTimeSecs = ((p.stimExpose)*(1000/p.RefreshRate))/1000;
p.trialTime = p.ITI+((p.stimExpose)*(1000/p.RefreshRate))/1000;
p.totalTime = p.trialTime*p.nTrials+p.endFix;
x = p.trialTime*p.nTrials+p.endFix;

% response key
% p.keys = 66; % response key is B
p.keys = KbName('1!');

%--------------------end user define parameters----------------------------%

p.gauss = ones(size(p.x));

% linearize output
dum = GetSecs;
% load('correctGammaScan_6209.mat');
correctGamma = linspace(0,1,256);
p.LUT = correctGamma*255;
p.bckGrnd = p.LUT(round(p.bckGrnd*255));

%Start setting up the display
AssertOpenGL; % bail if current version of PTB does not use OpenGL

% figure out how many screens we have, and pick the last one in the list
s=max(Screen('Screens'));

% grab the currecnt val for white and black for the selected screen, then
% compute middle gray
p.black = BlackIndex(s);
p.white = WhiteIndex(s);
p.gray=ceil((p.white+p.black)/2);
if round(p.gray)==p.white
    p.gray=p.black;
end
% find the 'real' value for gray after gamma correction using our
% Look-Up-Table. This gray will be used for the background so that our
% gaussian-windowed grating blend in smoothly with the background
p.gray = p.LUT(p.gray);

% Open a screen
Screen('Preference','VBLTimestampingMode',-1);  % for the moment, must disable high-precision timer on Win apps
if p.fullScreen
    [w, p.sRect] = Screen('OpenWindow', s, p.gray);
else
    % if we're dubugging open a 640x480 window that is a little bit down from the upper left
    % of the big screen
    [w, p.sRect]=Screen('OpenWindow',s, p.gray, [20,20,660,500]);
end

if p.fullScreen
    HideCursor;	% Hide the mouse cursor
    % set the priority up way high to discourage interruptions
    Priority(MaxPriority(w));
end

% compute and store the center of the screen: p.sRect contains the upper
% left coordinates (x,y) and the lower right coordinates (x,y)
p.xCenter = (p.sRect(3) - p.sRect(1))/2;
p.yCenter = (p.sRect(4) - p.sRect(2))/2;

% convert all 'Deg' fields from degrees to pixels, open the function for
% exact details on how to use - in short, all fields with the phrase 'Deg'
% in them anywhere will be converted to pixels, so take care when naming
% variables
p = deg2pix(p);

% destination rects for stim and fixation point
fixRect = [(p.xCenter  - p.fixSizePix),(p.yCenter - p.fixSizePix),(p.xCenter  + p.fixSizePix), (p.yCenter + p.fixSizePix)];
p.dstRect = [p.xCenter-p.stimSizePix, p.yCenter-p.stimSizePix, p.xCenter+p.stimSizePix, p.yCenter+p.stimSizePix];

% prepare text and center it
text1='Waiting for start of scanner';
tCenter1 = [p.xCenter-RectWidth(Screen('TextBounds', w, text1))/2 p.yCenter-120];

p.nBlocks = 1;
% start a block loop
for b=1:p.nBlocks
    %build an output file name and check to make sure that it does not exist already.
    p.root = pwd;
    if ~exist([p.root, '\Subject Data\'], 'dir')
        mkdir([p.root, '\Subject Data\']);
    end
    
    fName=[p.root, '\Subject Data\', p.subName,...
        '_fMRI', num2str(p.fMRI),...
        '_train', num2str(p.scanNum), '.mat'];
    
    if exist(fName,'file')
        Screen('CloseAll');
        msgbox('File name already exists, please specify another', 'modal')
        return;
    end
    
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
    
    %----------------------------------------------------------------------
    % Start the stimulus presentation stuff, wait for space bay or synch
    % pulse from the scanner
    %----------------------------------------------------------------------
    Screen('DrawText', w, text1, tCenter1(1), tCenter1(2), p.fixColor);
    Screen('FillOval', w, p.fixColor, fixRect);
    Screen('DrawingFinished', w);
    Screen('Flip', w);
    
    %after all initialization is done, sit and wait for scanner synch (or
    %space bar)
    while 1
        [resp, timeStamp] = checkForRespLoc([27,32,KbName('5%')]);
        if resp==32 || resp==KbName('5%')
            break;
        end
        if resp==-1; ListenChar(0); return; end;
    end
    
    cumTime = GetSecs;
    p.startExp = cumTime;
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
    % record end time of last stim
    p.endStimPeriod = GetSecs;
    
    % clear out screen
    Screen('FillOval', w, p.fixColor, fixRect);
    Screen('DrawingFinished', w);
    Screen('Flip', w);
    
    % wait the final fixation
    while GetSecs<=(p.totalTime+p.startExp)
        [resp, timeStamp] = checkForRespLoc([27,32]);
        if resp==-1; ListenChar(0); return; end;
    end
    
    p.EndExp = GetSecs;
    p.expDuration = p.EndExp - p.startExp;
    
    p.fullCor = p.correct/(p.nTargs*p.nTrials);
    
    %save trial data from this block
    save(fName, 'p');
    
    % put up a message to wait for a space bar press.
    %     str = sprintf('Full Contrast Correct: %5.2f, Press ''c'' Key', p.fullCor);
    %     [nx, ny, bbox] = DrawFormattedText(w, str, 'center', 'center', 0);
    %     Screen('Flip', w);
    %     resp = 0;
    %     while resp~=67
    %         [resp, timeStamp] = checkForRespLoc([27,67]);
    %         if resp==-1; ListenChar(0); return; end;
    %     end
    Screen('Flip', w);
end % end block loop

% restore keyboard, close up shop
ListenChar(0);
Screen('CloseAll');
return
