function data = setupDataTable( expParams, input, stim, expt )

load('D:\git\fMRI\VTF\lib\efficiency\model1_1-18-2018.mat');

data = table;
data.subject = repelem(input.subject, expParams.nTrials)';
data.trial = (1:expParams.nTrials)';

data.tStart_expected = (0:expParams.isi:expParams.scan_length_expected - expParams.isi )';
data.tEnd_expected = (expParams.isi:expParams.isi:expParams.scan_length_expected)';

data.tStart_realized = NaN([expParams.nTrials,1]);
data.tEnd_realized = NaN([expParams.nTrials,1]);

data.exitFlag = repmat({[]}, [expParams.nTrials,1]);

data.luminance_difference = NaN([expParams.nTrials,1]);
data.correct = NaN(expParams.nTrials,1);

%% main experimental parameters of interest
switch expt
    case 'contrast'
        
        data.orientation_left = stim.orientations_deg(mod(M.stimlist, expParams.nOrientations) + 1)';
        data.orientation_right = stim.orientations_deg(mod(M.stimlist, expParams.nOrientations) + 1)';
        data.orientation_left(M.stimlist==19) = 1;
        data.orientation_right(M.stimlist==19) = 1;
        data.contrast_left = stim.contrast((M.stimlist > expParams.nOrientations) + 1);
        data.contrast_right = stim.contrast((M.stimlist > expParams.nOrientations) + 1);
        data.contrast_left(M.stimlist==19) = 0;
        data.contrast_right(M.stimlist==19) = 0;
        
    case 'localizer'
        
        data.orientation_left1 = repelem(stim.orientations_deg(1),expParams.nTrials)';
        data.orientation_left2 = repelem(stim.orientations_deg(2),expParams.nTrials)';
        data.orientation_right1 = data.orientation_left1;
        data.orientation_right2 = data.orientation_left2;
        
        data.contrast_left1 = ones([expParams.nTrials,1]) * stim.contrast;
        data.contrast_right1 = ones([expParams.nTrials,1]) * stim.contrast;
        data.contrast_left2 = ones([expParams.nTrials,1]) * stim.contrast;
        data.contrast_right2 = ones([expParams.nTrials,1]) * stim.contrast;
        
end

end
