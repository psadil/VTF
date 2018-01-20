function tInfo = setupTInfo( expParams, stim )
%setupDebug setup values specific to debug levels

load('D:\git\fMRI\VTF\lib\efficiency\model1_1-18-2018.mat');
% := number of flips in a trial * number of trials + (1 flip for each ITI)
nFlips_total = stim.nFlipsPerTrial*expParams.nTrials;

tInfo = table;
tInfo.flip_id = (1:nFlips_total)';

% trial includes final ITI flip at end of trial
tInfo.trial = repelem(1:expParams.nTrials, stim.nFlipsPerTrial)';
tInfo.flipWithinTrial = repmat((1:(stim.nFlipsPerTrial))', [expParams.nTrials, 1]);

% for each flip, want to know when it flipped, when it should have flipped,
% and whether it missed
tInfo.vbl = NaN(nFlips_total, 1);
tInfo.vbl_fromTrigger_expected = NaN(nFlips_total, 1);
tInfo.missed = NaN(nFlips_total, 1);
tInfo.vbl_from0_expected = (0:stim.update_phase_sec:(expParams.scan_length_expected-stim.update_phase_sec))';

% On every trial's flip, one of the two gratings changes phase
% NaN indicates neither is changing (happens on ITI flip and first flip per trial)
tInfo.whichGratingToFlip =  repmat((1:2)', [nFlips_total/2, 1]);

% each flip of the stimulus has a random new phase (repeats are allowed)
tInfo.phase_orientation_left = ...
    randsample(linspace(0,360 - (360/stim.n_phase_orientations), stim.n_phase_orientations), ...
    nFlips_total, true)';
tInfo.phase_orientation_right = ...
    randsample(linspace(0,360 - (360/stim.n_phase_orientations), stim.n_phase_orientations), ...
    nFlips_total, true)';

% each grating should only change orientations on every other flip
tInfo.phase_orientation_left(2:2:end) = ...
    tInfo.phase_orientation_left(1:2:end);
tInfo.phase_orientation_right(3:2:end) = ...
    tInfo.phase_orientation_right(2:2:end-1);

% No phase presented during ITI, so this flip is gone
locationOfNull = ...
    any( tInfo.trial == find(M.stimlist==((expParams.nOrientations*expParams.nContrasts)+1))',2);
tInfo.phase_orientation_left(locationOfNull) = NaN;
tInfo.phase_orientation_right(locationOfNull) = NaN;

%% finally, set dimming sequence that occurs on each flip

tInfo.dimmed = zeros(nFlips_total,1);
flipsPerDim = expParams.fix_dim_dur_sec / stim.update_phase_sec;
flipsPerInterval = expParams.fix_dim_interval_sec / stim.update_phase_sec;
flip = 1;
while flip < nFlips_total - (flipsPerDim - 1)
    if flip > 10 && rand(1) < 0.3
        tInfo.dimmed(flip:(flip + (flipsPerDim - 1 ))) = 1;
        flip = flip + flipsPerDim + flipsPerInterval;
    else
        flip = flip + 1;
    end
end

end
