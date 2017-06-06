function structureCleanup(expt, subject, data, constants, varargin)
% receives structures of values relating to experiment and saves them all.
% constants must be defined so that it is known where to save the variables

constants.exp_end = GetSecs;

saveDir = fullfile(constants.subDir, expt);
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end

if p.fMRI
    fName=[p.root, '\Subject Data\', p.subName,...
        '_subNum', num2str(p.subNum),...
        '_allAttn_fMRI_Run', num2str(p.runNum),...
        '_Session', num2str(p.sessNum),...
        '_Block', num2str(blk),...
        '.mat'];   %MS change filename
else
    fName=[p.root, '\Subject Data\', p.subName,...
        '_subNum', num2str(p.subNum),...
        '_allAttn_Training_Run', num2str(p.runNum),...
        '_Session', num2str(p.sessNum),...
        '_Block', num2str(blk),...
        '.mat'];   %MS change filename
end



% save every list that has been given to windowCleanup
fNamePrefix = fullfile(saveDir, strjoin({'subject',num2str(subject),expt},'_'));
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
