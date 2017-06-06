function data = setupDataTable( expParams, input, stim )
%setupDataTable setup data table for this participant.

data = table;
data.subject = repelem(input.subject, expParams.nTrials)';
data.trial = (1:expParams.nTrials)';

data.tStart = NaN([expParams.nTrials,1]);
data.tEnd = NaN([expParams.nTrials,1]);

data.tStart_expected = NaN([expParams.nTrials,1]);
data.tEnd_expected = NaN([expParams.nTrials,1]);

data.stimOn = NaN([expParams.nTrials,1]);
data.stimOff = NaN([expParams.nTrials,1]);

data.RoboRT = repmat(1.5,[expParams.nTrials,1]);

data.exitFlag = repmat({[]}, [expParams.nTrials,1]);

data.correct = NaN(expParams.nTrials,1);
data.response = repmat({[]}, [expParams.nTrials,1]);
data.rt = NaN([expParams.nTrials,1]);
data.contStair = repmat({[NaN,NaN]},[expParams.nTrials,1]);

[data.tType, data.targOrient, data.cShift] = ...
    setupBlocking(expParams, stim);

data.answer = ...
    repmat({[]}, [expParams.nTrials,1]);
data.answer(data.answer == -1) = repmat({'\DOWN'},[expParams.nExpTrials/2,1]);
data.answer(data.answer == 1) = repmat({'\UP'},[expParams.nExpTrials/2,1]);

end

function [tType, targOrient, cShift] = setupBlocking(expParams, stim)

%{
Construct blocking of tType for contrast experiment

 
%}

% non-zeros targets/null targets(0)
% tType will be 'low contrast' and 'high contrast' trials
tType = ...
    [zeros(expParams.nNulls,1); repelem(1:2, expParams.nExpTrials/2)'];

% target orientations, making sure there are an equal number of each
targOrient = ...
    [repmat(stim.targOrients, expParams.nExpTrials/expParams.numOrients, 1);...
    zeros(expParams.nNulls,1)];

% make a vector to control 'higher' or 'lower' shifts in contrast...
% the contrast goes up on half trials (cShift = 1), and down on the other
% half (cShift = -1)
cShift = ...
    [zeros(expParams.nNulls, 1); repmat([1;-1], expParams.nExpTrials/2, 1)];

% make sure don't start with a null and that no two trials have the
% same or adjacent orientations
while 1
    if (tType(1)==0) ||...
            min(abs(diff(targOrient))) < (stim.uOrients(2) - stim.uOrients(1))
        rndInd = randperm(length(tType));
        tType = tType(rndInd);
        targOrient = targOrient(rndInd);
        cShift = cShift(rndInd);
    else
        break;
    end
end


end

