function structureCleanup(expt, subject, run, tInfo, constants, varargin)
% receives structures of values relating to experiment and saves them all.
% constants must be defined so that it is known where to save the variables

constants.exp_end = GetSecs;

% save every list that has been given to windowCleanup
fNamePrefix = fullfile(constants.subDir, strjoin({['sub-',num2str(subject, '%02d')],...
    ['task-', expt], ['run-', num2str(run, '%02d')]},'_'));

writetable(tInfo, [fNamePrefix, '_tInfo.tsv'], 'FileType', 'text', 'Delimiter', 'tab');

for nin = 5:nargin
    if nin == 5
        save([fNamePrefix,'_',inputname(nin),'.mat'],'constants');
    else
        variable = varargin{nin-5};  %#ok<NASGU>
        save([fNamePrefix,'_',inputname(nin),'.mat'],'variable');
    end
end

end