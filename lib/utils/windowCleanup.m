function windowCleanup(constants, eyetrackerFcn)
% receives structures of values relating to experiment and saves them all.
% constants must be defined so that it is known where to save the variables

eyetrackerFcn('StopRecording');
eyetrackerFcn('CloseFile');

rmpath(genpath(constants.lib_dir), constants.root_dir);

ListenChar(0);
Priority(0);
sca; % alias for screen('CloseAll')
end
