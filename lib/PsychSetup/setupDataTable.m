function data = setupDataTable( expParams, input, stim, expt )
%setupDataTable setup data table for this participant.

data = table;
data.subject = repelem(input.subject, expParams.nPhasesInRun)';
data.trial = repelem(1:expParams.nTrials, expParams.nPhasePerTrial)';

data.tStart_expected = repelem((0:expParams.trial_total_dur: ...
    (expParams.trial_total_dur*(expParams.nTrials-1)))', expParams.nPhasePerTrial);
data.tEnd_expected = repelem((expParams.trial_total_dur:expParams.trial_total_dur: ...
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

switch expt
    case 'contrast'
        data.rt_given = NaN([expParams.nPhasesInRun,1]);
        data.response_given = repmat({[]}, [expParams.nPhasesInRun,1]);
        
        % phaseTypeindicates whether dimming happens (1) or not (0) in phase
        data.phaseType = repmat([0,1,0,1,0]', [expParams.nTrials,1]);
        
        [data.orientation_left, data.contrast_left] = setupBlocking(expParams, stim);
        [data.orientation_right, data.contrast_right] = setupBlocking(expParams, stim);
        
        data.answer = repmat({[]}, [expParams.nPhasesInRun,1]);
        data.answer(data.phaseType == 0) = ...
            repmat({'NO RESPONSE'},[expParams.nTrials*(expParams.n_fix_dims+1),1]);
        data.answer(data.phaseType == 1) = ...
            repmat({'DownArrow'}, [expParams.nTrials*expParams.n_fix_dims,1]);
        
        data.roboResponse_expected = repmat({[]}, [expParams.nPhasesInRun,1]);
        data.roboResponse_expected(data.phaseType == 0) = ...
            repmat({''},[expParams.nTrials*(expParams.n_fix_dims+1),1]);
        data.roboResponse_expected(data.phaseType == 1) = ...
            repmat({'\DOWN'}, [expParams.nTrials*expParams.n_fix_dims,1]);
        
    case 'localizer'
        data.rt = repmat({repelem({NaN},expParams.nTargs)}, ...
            [expParams.nTrials,1]);
        data.response = repmat({repelem({[]},expParams.nTargs)}, ...
            [expParams.nTrials,1]);
        
        data.targFrame = repmat({repelem({NaN},expParams.nTargs)}, ...
            [expParams.nTrials,1]);
        data.targOnTime = repmat({repelem({NaN},expParams.nTargs)}, ...
            [expParams.nTrials,1]);
        data.targMaxRespTime = repmat({repelem({NaN},expParams.nTargs)}, ...
            [expParams.nTrials,1]);
        
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

