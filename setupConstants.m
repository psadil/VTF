function [constants, input, exit_stat] = setupConstants(input)
exit_stat = 0;
% defaults = ip.UsingDefaults;

constants.exp_start = GetSecs; % record the time the experiment began
constants.device = [];

% Get full path to the directory the function lives in, and add it to the path
constants.root_dir = fileparts(mfilename('fullpath'));
constants.lib_dir = fullfile(constants.root_dir, 'lib');

% add libraries to path
path(path, constants.root_dir);
path(path, genpath(constants.lib_dir));

constants.version = get_version_string('version.txt');

% Define the location of some directories we might want to use
switch input.responder
    case 'user'
        constants.savePath = fullfile(constants.root_dir, 'analyses', 'data');
    otherwise
        constants.savePath = fullfile(constants.root_dir,'analyses','robo');
end

constants.subDir = fullfile(constants.savePath, ['sub-', num2str(input.subject, '%02d')], 'beh');
if ~exist(constants.subDir, 'dir')
    mkdir(constants.subDir);
end

% instantiate the subject number validator function
runValidator = makeOverwriteChecker('run', constants.savePath, input.subject, input.debugLevel, input.experiment, input.run);
taskValidator = makeOverwriteChecker('task', constants.savePath, input.subject, input.debugLevel, input.experiment, input.run);

%% -------- GUI input option ----------------------------------------------------
% call gui for input
guiInput = getSubjectInfo('run', struct('title', 'Run Number', 'type', 'textinput',...
    'validationFcn', runValidator),...
    'experiment', struct('title', 'Run Type', 'type', 'dropdown',...
    'values', {{'contrast','localizer'}},'validationFcn', taskValidator) );
if isempty(guiInput)
    exit_stat = 1;
    return
else
    input = filterStructs(guiInput, input);
end
input.run = str2double(input.run);

switch input.responder
    case 'user'
        constants.func_dir = fullfile(constants.root_dir,'analyses','data',...
            ['sub-', num2str(input.subject, '%02d')], 'func');
    otherwise
        constants.func_dir = constants.subDir;
end
if ~exist(constants.func_dir, 'dir')
    mkdir(constants.func_dir)
end

constants.datatable_dir = fullfile(constants.root_dir, 'lib', 'datatables', ...
    ['sub-', num2str(input.subject, '%02d')]);

constants.data_grating_filename = fullfile(constants.datatable_dir,...
    ['sub-', num2str(input.subject, '%02d'), '_task-', input.experiment,...
    '_run-', num2str(input.run, '%02d'), '_grating.tsv']);

constants.tInfo_filename = fullfile(constants.datatable_dir,...
    ['sub-', num2str(input.subject, '%02d'), '_task-', input.experiment,...
    '_run-', num2str(input.run, '%02d'), '_tInfo.tsv']);

constants.data_dim_filename = fullfile(constants.datatable_dir,...
    ['sub-', num2str(input.subject, '%02d'), '_task-', input.experiment,...
    '_run-', num2str(input.run, '%02d'), '_dim.tsv']);

constants.data_eyelink_filename = ['scan', num2str(input.scan, '%02d'), '.edf'];

end


function overwriteCheck = makeOverwriteChecker(type, savepath, sub, debugLevel, task, run)
% makeSubjectDataChecker function closer factory, used for the purpose
% of enclosing the directory where data will be stored. This way, the
% function handle it returns can be used as a validation function with getSubjectInfo to
% prevent accidentally overwritting any data.

switch type
    case 'task'
        overwriteCheck = @taskGrabber;
    case 'run'
        overwriteCheck = @runGrabber;
end

    function [valid, msg] = taskGrabber(task, ~)
        [valid, msg] = fileChecker(sub, run, task);
    end

    function [valid, msg] = runGrabber(run, ~)
        [valid, msg] = fileChecker(sub, run, task);
    end

    function [valid, msg] = fileChecker(sub, run, task)
        % the actual validation logic
        valid = false;
        
        sub = num2str(sub, '%02d');
        run = num2str(run, '%02d');
        
        % directories often reused, so search for run folder
        behPathGlob = fullfile(savepath, ['sub-', sub], 'beh');
        runPathGlob = dir(behPathGlob);
        
        foundFile = zeros([size(runPathGlob,1),1]);
        for file = 1:size(runPathGlob,1)
            foundFile(file) = any(strfind(runPathGlob(file).name, ['task-', task, '_run-', run]));
        end
        
        if any(foundFile) && debugLevel < 1
            msg = strjoin({'data already exists!'}, ' ');
            return
        else
            valid = true;
            msg = 'ok';
        end
    end

end

