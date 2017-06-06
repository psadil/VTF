function rosieContrastPC_ps
%200 TRs @ 1.5s/TR
%150 TRs @ 2s/TR

warning('off','MATLAB:dispatcher:InexactMatch');
% Screen('Preference', 'SkipSyncTests', 1);

%get subject info
prompt = {'Subject Name', 'Sub Number', 'Session Number', 'Run Number', 'fMRI(1=Yes)','Contrast change [%,%]'};
%grab a random number and seed the generator (include this as a gui field
%in case want to repeat and exact sequence)
%fill in some stock answers to the gui input boxes
defAns = {'RR','1','1','1','1','8, 8'};
box = inputdlg(prompt,'Enter Subject Information...', 1, defAns);
if length(box)==length(defAns)      %simple check for enough input, otherwise bail out
   p.subName=char(box{1});p.subNum=str2double(box{2});p.sessNum=str2double(box{3});
   p.runNum=str2double(box{4});p.fMRI=str2double(box{5}); p.cChange=str2num(box{6})./100;
   p.rndSeed = round(sum(100*clock));
   rand('state',p.rndSeed);  %actually seed the random number generator
else    %if cancel button or not enough input, then just bail
   return
end

% if ~p.fMRI
%     p.runNum = 1:p.runNum;
% end

ListenChar(2);

%--------------------------------------------------------------------------
% Begin user params
%--------------------------------------------------------------------------
p.fullScreen = 1;                 % if 0 then the display will be in a small window, use this for debugging.

% monitor stuff
if ~p.fMRI
    p.RefreshRate = 120;               % refresh rate - not yet used xx
else
    p.RefreshRate = 120;
end

% total stim exposure duration
p.nTrials = 36;                   % nTrials=36 : 9 orientations, 2 samples per scan, two trial types (FD and CD) (False Detection and Correct Detection?)
p.nNulls = 8;                     % number of null 'fixation trials'
if p.fMRI==1
    p.nNulls = 8;
else
    p.nNulls = 0;
end
p.nTotalTrials = p.nTrials+p.nNulls;                         % number of trials 

% viewing distance and screen width, in CM...used to convert degrees visual
% angle to pixel units later on for drawing stuff
if p.fMRI
    p.screenWidthCM = 80;
    p.vDistCM = 137;
else 
    p.screenWidthCM = 34.29;
    p.vDistCM = 50.8;    
end

% stimulus timing stuff
p.cueExpose = .2; 
p.stimDur = 2;  %.8;         % stimulus duration in seconds
p.delay = .4;                % MS delay between sample & test (secs)
p.testDur = 2;               % MS test duration (secs)
p.respWin = 2;               % temporal window for a resp to be counted as correct, seconds: effectively serves as an ITI as well
p.trialDur = p.cueExpose+p.stimDur+p.delay+p.testDur+p.respWin;

p.tempFreq = 6;
p.maxJitterAngle = 3*pi/180;

p.contrast = [.3, .8];              % this is the contrast of the standard, all target contrasts will be relative to this
p.maxJitterContrast = 0; 

if p.contrast(2)+p.maxJitterContrast+p.cChange>1
    p.cChange = 0;%1-p.contrast+p.maxJitterContrast;
end

if p.fMRI
    p.postDur = 9;  % changed to 9 to make total time nice
else
    p.postDur = 0;
end

p.scanDur = p.postDur + (p.trialDur*p.nTotalTrials);
%stimulus colors
p.bckGrnd   = .5;

p.fixSizeDeg = .4;
p.fixLineSize = 2;

%stimulus properties
p.offXDeg = 0;                  % abs x offset of stimulus aperture from center in degrees 
p.offYDeg = 0;                % abs y offset of stimulus aperture from center in degrees 
%grating params (in degrees)
p.stimSizeDeg = 7.5;  % stim size in degrees (radius)
% p.n = 512;          % pixels
p.n = 2048;
[p.x,p.y] = meshgrid(linspace(-1,1,p.n));
p.innerR = .025;
p.sf = 5;%7;           % cycles/image
p.sig = .33;        % 1/e half width of gaussian

p.numOrients = 9;      %9 different directions
p.targOrients = linspace(0,180-(180/p.numOrients), p.numOrients)*pi/180;

p.fixColor = [255,255,255; 255,255,255; 255,255,255]; %MS Green fd, Blue contrast

p.fixSizeDeg = .25;                  % length of the lines
p.fontSize = 24;
p.textColor = [125, 125, 125];  % oldTextColor=Screen('TextColor', windowPtr [,colorVector]);

%Response keys
if p.fMRI
    p.keys = [KbName('1!'),KbName('2@')]; % decreased constrast, increased contrast
else
    p.keys = [KbName('z'),KbName('x')];
end
p.space = KbName('space');
p.start = KbName('5%');

if ismac
    p.escape = 41;
else
    p.escape = 27;
end

% staircasing stuff only used for behavioral
% QUEST staircasing
% the params for the detection task
p.delta=0.01; p.gamma=0.5;
p.beta=3.5;
p.priorSd = 3;
p.Correct_quest=0.75; 
p.thresholdGuess_con=log10(.1);
p.max_con = 1-p.contrast(2)+p.maxJitterContrast;       % make sure we don't ever try to draw a stim with contrast > 1
p.min_con = .01; % min=1 intensity unit

%initialize the contrast & orient params (these might be overridden later by the values from
%the previous block)
p.cdThresh = p.cChange;           % start contrast level 

%feedback beeps
if ~p.fMRI && ~ismac
    dur = .1; % in sec
    sr = 44100; %sampling rate
    samp = 0:1/sr:dur;

    corbeep = sin(2*pi*samp*1000); %3000 Hz
    audiowrite('cor_beep.wav',corbeep, sr)
    [cor, sr] = audioread('cor_beep.wav');

    incorbeep = sin(2*pi*samp*3000); %1000 Hz
    audiowrite( 'incor_beep.wav', incorbeep, sr)
    [incor, sr] = audioread('incor_beep.wav');
end

%--------------------------------------------------------------------------
% End user params
%--------------------------------------------------------------------------

% load gamma file for the scanner (or for whatever room you're in! xx important xx)
% load('correctGammaScan_6209.mat');
correctGamma = linspace(0,1,256)';
p.LUT = correctGamma*255; %LUT is look-up-table

p.bckGrnd = p.LUT(round(p.bckGrnd*255));

%Start setting up the display
AssertOpenGL; % bail if current version of PTB does not use OpenGL

% figure out how many screens we have, and pick the last one in the list
s=max(Screen('Screens'));

% grab the current val for white and black for the selected screen, then
% compute middle gray
p.black = BlackIndex(s);
p.white = WhiteIndex(s);
p.gray=ceil((p.white+p.black)/2);
if round(p.gray)==p.white
    p.gray=p.black;
end
inc = p.white - p.gray;
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
    [w, p.sRect]=Screen('OpenWindow',s, p.gray, [600,50,960,290]);    
end

% compute and store the center of the screen: p.sRect contains the upper
% left coordinates (x,y) and the lower right coordinates (x,y)
p.xCenter = (p.sRect(3) - p.sRect(1))/2;
p.yCenter = (p.sRect(4) - p.sRect(2))/2;
center = [(p.sRect(3) - p.sRect(1))/2, (p.sRect(4) - p.sRect(2))/2];

% XX 9.16.2010
% convert all 'Deg' fields from degrees to pixels, open the function for
% exact details on how to use - in short, all fields with the phrase 'Deg'
% in them anywhere will be converted to pixels, so take care when naming
% variables
p = deg2pix(p);

% Definition of the drawn source rectangle on the screen:
srcRect = [p.xCenter-p.offXPix-p.stimSizePix, p.yCenter-p.offYPix-p.stimSizePix, p.xCenter-p.offXPix+p.stimSizePix, p.yCenter-p.offYPix+p.stimSizePix];

if p.fullScreen
    HideCursor;	% Hide the mouse cursor
    % set the priority up way high to discourage interruptions
    Priority(MaxPriority(w));
end

% test the refresh properties of the display
p.fps=Screen('FrameRate',w);          % frames per second
p.ifi=Screen('GetFlipInterval', w);   % inter-frame-time
p.waitframes = 1;
p.waitduration = p.waitframes * p.ifi;
if p.fps==0                           % if fps does not register, then set the fps based on ifi
 p.fps=1/p.ifi;
end

% check that the actual refresh rate is what we expect it to be.
if abs(p.fps-p.RefreshRate)>5
    Screen('CloseAll');
    disp('Set the refresh rate to the requested rate')
    ListenChar(0);
    clear all;
    return;
end

% cue point coordinates
fixRect = [(p.xCenter  - p.fixSizePix),(p.yCenter - p.fixSizePix),(p.xCenter  + p.fixSizePix), (p.yCenter + p.fixSizePix)];

% set up the font
if ismac
    Screen('TextFont',w, 'Helvetica');
else
    Screen('TextFont',w, 'Arial');    
end
Screen('TextSize',w, p.fontSize);
Screen('TextStyle', w, 0);
Screen('TextColor', w, p.black);
Screen('TextBackgroundColor', w, p.gray);

%--------------------------------------------------------------------------
% Generate time sequence for a trial.
% freqSeq determines flicker of stim
%p.cueExpose = round(p.cueExpose/p.ifi);
p.stimDur = round(p.stimDur/p.ifi);
p.delay = round(p.delay/p.ifi);
p.testDur = round(p.testDur/p.ifi);
p.maxTrialFrames = p.cueExpose + p.stimDur + p.delay + p.testDur;

% flicker sequence
p.flicker=[];
for ii=1:(p.stimDur/(p.tempFreq*2))
    p.flicker = [p.flicker, [repmat(1,1,p.tempFreq),repmat(0,1,p.tempFreq)]]; 
end
% double the length, just in case some monitors refresh rate is slightly
% above requested (so we don't index beyond the end of the array)
p.flicker = [p.flicker, p.flicker];

% make the possible gratings on full contrast 'training trials'        
uOrients = unique(p.targOrients); 

% set up the quest staircases
p.conq(1)=QuestCreate(p.thresholdGuess_con,p.priorSd,p.Correct_quest,p.beta,p.delta,p.gamma,p.min_con,3);
p.conq(2)=QuestCreate(p.thresholdGuess_con,p.priorSd,p.Correct_quest,p.beta,p.delta,p.gamma,p.min_con,3);

blkCnt = 1;
p.nBlocks = 1;
% block loop
for blk = p.nBlocks
    
    % don't overwrite any data on accident...also make a subject data folder if
    % one does not already exist to store all output files
    p.root = pwd;
    if ~exist([p.root, '\Subject Data\'], 'dir')
        mkdir([p.root, '\Subject Data\']);
    end

    if p.fMRI
        fName=[p.root, '\Subject Data\', p.subName,...
            '_subNum', num2str(p.subNum),...
            '_allAttn_fMRI_Run', num2str(p.runNum),...
            '_Session', num2str(p.sessNum),...
            '_Block', num2str(blk),...
            '.mat'];   %MS change filename
    else
        fName=[p.root, '\Subject Data\', p.subName,...
            '_subNum', num2str(p.subNum),...
            '_allAttn_Training_Run', num2str(p.runNum),...
            '_Session', num2str(p.sessNum),...
            '_Block', num2str(blk),...
            '.mat'];   %MS change filename
    end

    if exist(fName,'file')
        Screen('CloseAll');
        msgbox('File name already exists, please specify another', 'modal')
        return;
    end
   
    % ----------------------
    % Generate stimulus sequence
    % ----------------------    
    % non-zeros targets/null targets(0)
    % tType will be 'low contrast' and 'high contrast' trials
    p.tType = [sort(repmat([1;2], p.nTrials/2, 1)); zeros(p.nNulls,1)];    
    % target orientations, making sure there are an equal number of each
    p.targOrient = [repmat(uOrients', p.nTrials/length(uOrients), 1); zeros(p.nNulls,1)];   
    % make a vector to control 'higher' or 'lower' shifts in contrast...
    p.cShift = [repmat([1;-1], p.nTrials/2, 1)];
    p.cShift = p.cShift(randperm(length(p.cShift)));    % mix it up
    p.cShift = [p.cShift; zeros(p.nNulls, 1)];          % then tack on nulls and mix it up again with the other vecs so that nulls in same spot for all.
    
    % then scramble ALL the vectors with the same rand sequence so that
    % nulls line up across vectors.
    p.rndInd = randperm(length(p.tType));
    p.tType = p.tType(p.rndInd);
    p.targOrient = p.targOrient(p.rndInd); 
    p.cShift = p.cShift(p.rndInd);    
    % make sure don't start with a null and that no two trials have the
    % same or adjacent orientations
    while 1
        if (p.tType(1)==0) || min(abs(diff(p.targOrient)))<(uOrients(2)-uOrients(1))
            p.rndInd = randperm(length(p.tType));
            p.tType = p.tType(p.rndInd);
            p.targOrient = p.targOrient(p.rndInd);
            p.cShift = p.cShift(p.rndInd);
        else
            break;
        end    
    end
    
    %---------------------------------
    % initialize some storage variables
    %---------------------------------
    p.correct = zeros(p.nTotalTrials,1);
    p.resp = zeros(p.nTotalTrials,1);
    p.rt = nan(p.nTotalTrials,1);
    p.contStair = nan(length(p.contrast), p.nTrials*length(p.runNum),1);  
 
    %----------------------------------------------------------------------
    % put up a message to wait for a space bar press. we'll also do this at
    % the end of each trial
    % initialize the text messages for subject feedback - only need to do this
    % once, not on every trial

    text1='Attend Contrast (Lower/Higher)';
    tCenter1 = [p.xCenter-RectWidth(Screen('TextBounds', w, text1))/2 p.yCenter-120];
    Screen('DrawText', w, text1, tCenter1(1), tCenter1(2), p.fixColor(3,:));
    Screen('FillOval', w, p.fixColor(3,:), fixRect);
    Screen('DrawingFinished', w);
    Screen('Flip', w);
    
    p.trialStart = zeros(1, p.nTotalTrials);
    p.stimEnd = zeros(1, p.nTotalTrials);
    p.trialEnd = zeros(1, p.nTotalTrials);
    p.startExp = 0;
    p.endExp = 0;
    
    % after all initialization is done, sit and wait for scanner synch (or
    % space bar)
    % after scanner synch is detected, enter the trial loop
    while 1
       [resp, timeStamp] = checkForResp([p.escape,p.space,p.start]);
       if resp==p.space || resp==p.start
           break;
       end
       if resp==p.escape; 
           ListenChar(0); 
           Screen('CloseAll'); 
           return; 
       end
    end
    cumTime = GetSecs;
    p.startExp = cumTime;      
    rTcnt = 1;
    for t = 1:p.nTotalTrials
        % record the trial onset time
        p.trialStart(t) = GetSecs;
        
        % if its a null trial, just sit and wait
        if p.tType(t)==0            
            Screen('FillOval', w, p.fixColor(3,:), fixRect); % MS color depends on trial type
            Screen('DrawingFinished', w);
            Screen('Flip', w); 
            while GetSecs <= cumTime+p.trialDur
                [resp, timeStamp] = checkForResp([p.escape,p.space]);
                if resp==p.escape; ListenChar(0); Screen('CloseAll'); return; end;
            end
            cumTime = cumTime+p.trialDur;
        
        else    % real trial           
            % put up the cue
            Screen('FillOval', w, p.fixColor(p.tType(t),:), fixRect); % MS color depends on trial type
            Screen('DrawingFinished', w);
            Screen('Flip', w); 

            % then pick the contrast of each XX 9.2010 - all contrast stuff
            % is set to 0 for now - just leaving in for later if we want it
            p.firstContrast(t) = p.contrast(p.tType(t))+(rand-.5)*(p.maxJitterContrast*2);
            p.secondContrast(t) = p.firstContrast(t)+p.cdThresh(p.tType(t))*p.cShift(t); 
            
            img = makeGrating(p, p.sf, p.targOrient(t), p.firstContrast(t), rand*pi);
            stim1=Screen('MakeTexture', w, img);
            img = makeGrating(p, p.sf, p.targOrient(t), p.secondContrast(t), rand*pi);
            stim2=Screen('MakeTexture', w, img);
            
            % keep track of the values on this trial by filling in
            % staircases. Note: these values will only change (be
            % staircased) during training
            p.contStair((p.tType(t)), blkCnt*p.nTotalTrials-p.nTotalTrials + t) = p.cdThresh(p.tType(t));
            
            % soak up the remaining cue expose time, then move on
            while GetSecs<=cumTime+p.cueExpose
                if checkForResp(p.escape); Screen('CloseAll'); ListenChar(0); return; end;                  
            end
            frmCnt = 1;
            
            resp = 1;
            % put up the first interval
            for i=1:p.stimDur                
                % check for valid response keys...
                if ~resp
                    [resp, timeStamp] = checkForResp([p.keys, p.escape]);
                    if resp==p.escape; ListenChar(0); Screen('CloseAll'); return; end;
                end 
                
                if p.flicker(i)==1     
                    Screen('DrawTexture', w, stim1, [], srcRect, [], 1);
                end   

                Screen('FillOval', w, p.fixColor(1,:), fixRect); % MS color depends on trial type                                
                frmCnt = frmCnt + 1;
                Screen('DrawingFinished', w);
                Screen('Flip', w); 
            end 
            
            %DELAY
            for i=1:p.delay
                if checkForResp(p.escape);  Screen('CloseAll'); ListenChar(0); return; end;                
                Screen('FillOval', w, p.fixColor(p.tType(t),:), fixRect); % MS color depends on trial type
                Screen('DrawingFinished', w);
                Screen('Flip', w); 
            end

            % open the response window for orientation and contrast blks
            resp = 0;

            %Second interval
            stim2up = GetSecs;
            for i=1:p.stimDur   
                % check for valid response keys...
                if ~resp
                    [resp, timeStamp] = checkForResp([p.keys, p.escape]);
                    if resp==p.escape; ListenChar(0); Screen('CloseAll'); return; end;
                end

                if p.flicker(i)==1
                    Screen('DrawTexture', w, stim2, [], srcRect, [], 1);
                end       

                Screen('FillOval', w, p.fixColor(1,:), fixRect); % MS color depends on trial type                
                frmCnt = frmCnt + 1;                
                Screen('DrawingFinished', w);
                Screen('Flip', w); 
            end 
            Screen('FillOval', w, p.fixColor(1,:), fixRect); % MS color depends on trial type
            Screen('DrawingFinished', w);
            Screen('Flip', w); 
            p.stimEnd(t) = GetSecs;
           
            %collect/and or evaluate the response
            getResp = 1;
            while GetSecs <= cumTime + p.trialDur
                % query keyboard for possible response (or for escape key -
                % exit)
                if ~resp
                    [resp, timeStamp] = checkForResp(p.keys);
                    if resp==p.escape; ListenChar(0); Screen('CloseAll'); return; end;
                end
                if resp && getResp
                    p.resp(t) = find(resp==p.keys);
                    p.rt(t) = timeStamp-stim2up;

                    if p.cShift(t)<0 % contrast decrement
                        if p.resp(t) == 1
                            p.correct(t) = 1;
                        else
                            p.correct(t) = 0;
                        end
                        getResp = 0;
                    else            % contrast increment
                        if p.resp(t) == 2
                            p.correct(t) = 1;
                        else
                            p.correct(t) = 0;
                        end 
                        getResp = 0;
                    end

                end %if resp && getResp
                
            end %while respWin
            

            if ~p.fMRI && ~ismac
                if p.correct(t) == 1
                    sound(cor, sr)
                else
                    sound(incor, sr)
                end
            end

            cumTime = cumTime + p.trialDur;   
            
            % adjust the offsets if a training session
%             if ~p.fMRI 
                p.conq(p.tType(t))=QuestUpdate(p.conq(p.tType(t)),log10(p.cdThresh(p.tType(t))),p.correct(t));
                %QuestQuantile suggestion for next contrast 
                p.cdThresh(p.tType(t))=10.^QuestQuantile(p.conq(p.tType(t)));
                if p.cdThresh(p.tType(t))>p.max_con
                    p.cdThresh(p.tType(t))=p.max_con;
                elseif p.cdThresh(p.tType(t))<p.min_con
                    p.cdThresh(p.tType(t))=p.min_con;
                end 
%             end
%             fprintf('%d\t%d\t%f\n', p.correct(t), resp, p.odThresh)
            rTcnt = rTcnt+1;
            p.trialEnd(t) = GetSecs;
        end  % end of this trial
    p.cdThresh
    end %end of loop over all trials
    
    p.endStimTime = GetSecs-p.startExp;
    
    % wait post dur
    if p.fMRI
        while GetSecs<=p.startExp+p.scanDur
            if checkForResp(p.escape); ListenChar(0); return; end;                         
        end
    end
    %save the data...
    p.endExp = GetSecs;
    p.expDuration = p.endExp - p.startExp;
    
    if ~p.fMRI
        p.acc = nanmean(p.correct);
    else
        p.acc = sum(p.correct)/p.nTrials; %so that null trials do not get counted as incorrect responses
    end
        
    save(fName, 'p');
    
    %wait for 'c' key to continue
%     [nx, ny, bbox] = DrawFormattedText(w, sprintf('Accuracy: %f, press ''space'' to continue', p.acc), 'center', 'center', 0);
%     Screen('Flip', w);
%     fprintf('%5.6f\n', p.acc);
   % if waitTillKey(p.space); ListenChar(0); return; end;
    Screen('Flip', w);
    blkCnt = blkCnt + 1;
    
%     figure (blk);
%     subplot(1,2,1);
%     threshStair1 = p.contStair(1,~isnan(p.contStair(1,:)));
%     stairs(1:length(threshStair1),threshStair1);
%     title('Low Contrast Thresholds');
%     subplot(1,2,2);    
%     threshStair2 = p.contStair(2,~isnan(p.contStair(2,:)));
%     stairs(1:length(threshStair2),threshStair2);
%     title('High Contrast Thresholds');
end %block loop

% finish up and close
ListenChar(0);
Screen('CloseAll');

return