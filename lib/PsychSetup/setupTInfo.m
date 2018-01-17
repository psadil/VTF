function tInfo = setupTInfo( expParams, stim, data )
%setupDebug setup values specific to debug levels

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
tInfo.vbl_from0_expected = (0:stim.update_phase_sec:(stim.update_phase_sec*nFlips_total - stim.update_phase_sec))' + ...
    expParams.iti_dur_sec * repelem(0:expParams.nTrials-1, stim.nFlipsPerTrial)' - ...
    stim.update_phase_sec * repelem(0:expParams.nTrials-1, stim.nFlipsPerTrial)';
tInfo.missed = NaN(nFlips_total, 1);

% On every trial's flip, one of the two gratings changes phase
% NaN indicates neither is changing (happens on ITI flip and first flip per trial)
whichGratingToFlipInTrial = [NaN, repmat(1:2, [1,stim.nFlipsPerTrial/2 - 1]), NaN]';
tInfo.whichGratingToFlip =  repmat(whichGratingToFlipInTrial, [expParams.nTrials, 1]);

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
tInfo.phase_orientation_left(stim.nFlipsPerTrial:stim.nFlipsPerTrial:end) = NaN;
tInfo.phase_orientation_right(stim.nFlipsPerTrial:stim.nFlipsPerTrial:end) = NaN;

%% finally, set dimming sequence that occurs on each flip

tInfo.dimmed = zeros(nFlips_total,1);
for flip = 1:nFlips_total
    if (isclose_or_greater(tInfo.vbl_from0_expected(flip), data(data.trial==tInfo.trial(flip),:).phaseStart_expected(2)) && ...
            tInfo.vbl_from0_expected(flip) < data(data.trial==tInfo.trial(flip),:).phaseStart_expected(3)) || ...
            (isclose_or_greater(tInfo.vbl_from0_expected(flip), data(data.trial==tInfo.trial(flip),:).phaseStart_expected(4)) && ...
            tInfo.vbl_from0_expected(flip) < data(data.trial==tInfo.trial(flip),:).phaseStart_expected(5))
        tInfo.dimmed(flip) = 1;
    end
end

end

function out = isclose(a,b)

reletive_error = 1e-12;
out = abs(a-b) < reletive_error * max(a,b);

end

function out = isclose_or_greater(a,b)

out = isclose(a,b) || a > b;

end

