function tInfo = setupTInfo( constants )
%setupDebug setup values specific to debug levels

tInfo = struct2table(tdfread(constants.tInfo_filename, 'tab'));

% categorical structure saves a bit of memory when possible
tInfo.trial_type = categorical(cellstr(tInfo.trial_type));
tInfo.side = categorical(cellstr(tInfo.side));
tInfo.filename = [];

% categorical structure saves a bit of memory when possible
tInfo.event = cellstr(tInfo.event);
tInfo.response = cellstr(tInfo.response);
tInfo.answer = cellstr(tInfo.answer);
tInfo.exitflag = cellstr(tInfo.exitflag);

tInfo.orientation = str2double(cellstr(tInfo.orientation)); 
tInfo.correct = str2double(cellstr(tInfo.correct)); 
tInfo.contrast = str2double(cellstr(tInfo.contrast)); 


phases = linspace(0, 180 - 16, 16);

n_flip = max(tInfo.flip);

tInfo.phase = NaN(size(tInfo,1), 5);
tInfo.phase = reshape(randsample(phases, numel(tInfo.phase), true), size(tInfo.phase));
tInfo.phase(tInfo.side == 'left' & ismember(tInfo.flip, 2:2:n_flip)) = ...
    tInfo.phase(tInfo.side == 'left' & ismember(tInfo.flip, 1:2:n_flip));
tInfo.phase(tInfo.side == 'right' & ismember(tInfo.flip, 3:2:n_flip)) = ...
    tInfo.phase(tInfo.side == 'right' & ismember(tInfo.flip, 2:2:n_flip-1));


end
