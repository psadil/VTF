function structureCleanup(expt, subject, data, constants, varargin)
% receives structures of values relating to experiment and saves them all.
% constants must be defined so that it is known where to save the variables

constants.exp_end = GetSecs;

% save every list that has been given to windowCleanup
fNamePrefix = fullfile(constants.subDir, strjoin({['sub-',num2str(subject, '%02d')], ['task-', expt]},'_'));
writetable(data, [fNamePrefix,'.csv']);
for nin = 4:nargin
    if nin == 4
        save([fNamePrefix,'_',inputname(nin),'.mat'],'constants');
    else
        variable = varargin{nin-4};
        save([fNamePrefix,'_',inputname(nin),'.mat'],'variable');
    end
end

end