function acc = checkAccuracy( data )

% data.rt = cell2mat(data.rt);

% grpmeans = grpstats(data,'phaseType', 'nanmean','DataVars','correct');
% acc = grpmeans.nanmean_correct(1);
acc = nanmean(data.correct);

end

