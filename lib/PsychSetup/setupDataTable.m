function data = setupDataTable( expParams, input, stim, expt, keys )
%setupDataTable setup data table for this participant.

data = table;
data.subject = repelem(input.subject, expParams.nPhasesInRun)';
data.trial = repelem(1:expParams.nTrials, expParams.nPhasePerTrial)';
data.phase = repmat((1:expParams.nPhasePerTrial)', [expParams.nTrials,1]);

data.tStart_expected = repelem((0:expParams.trial_total_dur: ...
    (expParams.trial_total_dur*(expParams.nTrials-1)))', expParams.nPhasePerTrial);
data.tEnd_expected = repelem((expParams.trial_stim_dur_sec:expParams.trial_total_dur: ...
    (expParams.trial_total_dur*(expParams.nTrials)))', expParams.nPhasePerTrial);

data.phaseStart_expected = NaN([expParams.nPhasesInRun,1]);
% must start first dim after at least .5 sec into trial, and (.5 + 1 + .5) before end
% rounding for maximum flicker rate
% shifting so that timing is with respect to start of experiment
data.phaseStart_expected(1:5:end) = data.tStart_expected(1:5:end);
data.phaseStart_expected(2:5:end) = data.phaseStart_expected(1:5:end) + ...
    round(.5 + (3-.5)*rand(expParams.nPhasesInRun / expParams.nPhasePerTrial,1),1);
data.phaseStart_expected(3:5:end) = data.phaseStart_expected(2:5:end) + expParams.fix_dim_dur_sec;
data.phaseStart_expected(4:5:end) = data.phaseStart_expected(3:5:end) + ...
    round(expParams.fix_dim_interval_range_sec(1) + ...
    (expParams.fix_dim_interval_range_sec(2) - expParams.fix_dim_interval_range_sec(1))*...
    rand(expParams.nPhasesInRun /expParams.nPhasePerTrial ,1),1);
data.phaseStart_expected(5:5:end) = data.phaseStart_expected(4:5:end) + expParams.fix_dim_dur_sec;

data.tStart_realized = NaN([expParams.nPhasesInRun,1]);
data.tEnd_realized = NaN([expParams.nPhasesInRun,1]);
data.phaseStart_realized = NaN([expParams.nPhasesInRun,1]);

% RT robot tries to acheive
data.roboRT_expected = repmat(0.2,[expParams.nPhasesInRun,1]);

data.exitFlag = repmat({[]}, [expParams.nPhasesInRun,1]);

data.correct = NaN(expParams.nPhasesInRun,1);

data.rt_given = NaN([expParams.nPhasesInRun,1]);
data.response_given = repmat({[]}, [expParams.nPhasesInRun,1]);

% phaseTypeindicates whether dimming happens (1) or not (0) in phase
data.phaseType = repmat([repmat([0;1], [expParams.n_fix_dims,1]);0],... 
    [expParams.nTrials,1]);

data.answer = repmat({[]}, [expParams.nPhasesInRun,1]);
data.answer(data.phaseType == 0) = ...
    repmat({'NO RESPONSE'},[expParams.nTrials*(expParams.n_fix_dims+1),1]);
data.answer(data.phaseType == 1) = ...
    repmat({KbName(keys.resp)}, [expParams.nTrials*expParams.n_fix_dims,1]);

data.roboResponse_expected = repmat({[]}, [expParams.nPhasesInRun,1]);
data.roboResponse_expected(data.phaseType == 0) = ...
    repmat({'z'},[expParams.nTrials*(expParams.n_fix_dims+1),1]);
data.roboResponse_expected(data.phaseType == 1) = ...
    repmat({keys.robo_resp}, [expParams.nTrials*expParams.n_fix_dims,1]);

data.luminance_difference = NaN([expParams.nPhasesInRun,1]);

switch expt
    case 'contrast'
        
        [data.orientation_left, data.contrast_left] = setupBlocking(expParams, stim);
        [data.orientation_right, data.contrast_right] = setupBlocking(expParams, stim);
        
    case 'localizer'
        
        data.orientation_left1 = repelem(stim.orientations_deg(1),expParams.nPhasesInRun)';
        data.orientation_left2 = repelem(stim.orientations_deg(2),expParams.nPhasesInRun)';
        data.orientation_right1 = data.orientation_left1;
        data.orientation_right2 = data.orientation_left2;
        
        data.contrast_left1 = ones([expParams.nPhasesInRun,1]) * stim.contrast;
        data.contrast_right1 = ones([expParams.nPhasesInRun,1]) * stim.contrast;
        data.contrast_left2 = ones([expParams.nPhasesInRun,1]) * stim.contrast;
        data.contrast_right2 = ones([expParams.nPhasesInRun,1]) * stim.contrast;
        
end

end

function [orientations, contrasts] = setupBlocking(expParams, stim)

%{
Construct blocking of tType for contrast experiment

tType Key:
1:expParams.nOrientations = low contrast
1+expParams.nOrientations : (2*expParams.nOrientations) = high contrast
%}

tType = Shuffle(repmat(( 1:(expParams.nOrientations*expParams.nContrasts))',...
    [expParams.reps, 1]) );

orientations = stim.orientations_deg(mod(tType, expParams.nOrientations)+1)';
contrasts = stim.contrast((tType > expParams.nOrientations) + 1);

orientations = repelem(orientations, expParams.nPhasePerTrial);
contrasts = repelem(contrasts, expParams.nPhasePerTrial);

end

