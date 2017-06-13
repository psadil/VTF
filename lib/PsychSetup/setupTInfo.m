function tInfo = setupTInfo( expParams, nTicks )
%setupDebug setup values specific to debug levels

tInfo = table;
tInfo.trial = repelem(1:expParams.nTrials, nTicks)';
tInfo.tick = repmat((1:nTicks)', [expParams.nTrials, 1]);

tInfo.vbl = NaN(expParams.nTrials*nTicks, 1);
tInfo.missed = NaN(expParams.nTrials*nTicks, 1);



end
