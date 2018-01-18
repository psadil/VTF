function [constants, input, exit_stat] = setupConstants(input, ip)
exit_stat = 0;
% defaults = ip.UsingDefaults;

constants.exp_start = GetSecs; % record the time the experiment began
constants.device = [];

% Get full path to the directory the function lives in, and add it to the path
constants.root_dir = fileparts(mfilename('fullpath'));
constants.lib_dir = fullfile(constants.root_dir, 'lib');

% add libraries to path
path(path,constants.root_dir);
path(path, genpath(constants.lib_dir));

% Define the location of some directories we might want to use
switch input.responder
    case 'user'
        constants.savePath=fullfile(constants.root_dir,'analyses','data','beh');
    otherwise
        constants.savePath=fullfile(constants.root_dir,'analyses','robo');
end
% instantiate the subject number validator function
subjectValidator = makeSubjectDataChecker(constants.savePath, input.subject, input.debugLevel);

%% -------- GUI input option ----------------------------------------------------

% call gui for input
guiInput = getSubjectInfo('run', struct('title', 'Run Number', 'type', 'textinput',...
    'validationFcn', subjectValidator));
if isempty(guiInput)
    exit_stat = 1;
    return
else
    input = filterStructs(guiInput, input);
end

if ~isnumeric(input.run)
   input.run = str2double(input.run); 
end

% now that we have all the input and it has passed validation, we can have
% a file path!
constants.subDir = fullfile(constants.savePath, ['sub-', num2str(input.subject, '%02d')]);
if ~exist(fullfile(constants.subDir), 'dir')
    mkdir(fullfile(constants.subDir));
end

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

end


function overwriteCheck = makeSubjectDataChecker(directory, subnum, debugLevel)
% makeSubjectDataChecker function closer factory, used for the purpose
% of enclosing the directory where data will be stored. This way, the
% function handle it returns can be used as a validation function with getSubjectInfo to
% prevent accidentally overwritting any data.
    function [valid, msg] = subjectDataChecker(value, ~)
        % the actual validation logic
        valid = false;
        
        run = str2double(value);
        if (~isnumeric(subnum) || isnan(subnum)) && ~isnumeric(value)
            msg = 'Subject Number must be greater than 0';
            return
        end
        
        % directories often reused, so search for run folder
        dirPathGlob = fullfile(directory, ['sub-', num2str(subnum, '%02d')]);
        if exist(dirPathGlob,'dir')
            
            runPathGlob = dir(dirPathGlob);
            foundFile = zeros([size(runPathGlob,1),1]);
            for file = 1:size(runPathGlob,1)
                foundFile(file) = contains(runPathGlob(file).name, ['run-', num2str(run, '%02d')]);
            end
            
            if any(foundFile) && debugLevel <= 10
                msg = strjoin({'Data file for Subject', num2str(subnum), 'run', value, 'already exists!'}, ' ');
                return
            else
                valid = true;
                msg = 'ok'; 
            end
        end
    end

overwriteCheck = @subjectDataChecker;
end

