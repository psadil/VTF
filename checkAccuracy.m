function acc = checkAccuracy( data )

data.rt = cell2mat(data.rt);

grpmeans = grpstats(data, 'tType','nanmean', 'DataVars','correct');
acc = grpmeans.nanmean_correct(1);

end

