function dimming_data = setupDataDimming( expParams, input, keys )

load('D:\git\fMRI\VTF\lib\efficiency\model1_1-18-2018.mat');

dimming_data = table;
dimming_data.subject = repelem(input.subject, expParams.maxPhasesPerRun)';
dimming_data.trial = repelem(1:expParams.nTrials,expParams.maxPhasePerTrial)';

dimming_data.phaseWithinTrial = repmat((1:expParams.maxPhasePerTrial)',[expParams.nTrials,1]);

dimming_data.answer = repmat({[]}, [expParams.maxPhasesPerRun,1]);
dimming_data.answer(mod(dimming_data.phaseWithinTrial,2)==1) = {'NO_RESPONSE'};
dimming_data.answer(mod(dimming_data.phaseWithinTrial,2) == 0) = {KbName(keys.resp)};

dimming_data.roboResponse_expected = repmat({[]}, [expParams.maxPhasesPerRun,1]);
dimming_data.roboResponse_expected(mod(dimming_data.phaseWithinTrial,2)==1) = {'z'};
dimming_data.roboResponse_expected(mod(dimming_data.phaseWithinTrial,2) == 0) = {keys.robo_resp};

dimming_data.roboRT_expected = repelem(0.2, expParams.maxPhasesPerRun)';

dimming_data.rt_given = NaN([expParams.maxPhasesPerRun,1]);
dimming_data.response_given = repmat({[]}, [expParams.maxPhasesPerRun,1]);

end
