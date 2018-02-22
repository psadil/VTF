function windowCleanup(constants, eyetrackerFcn, fb)
% receives structures of values relating to experiment and saves them all.
% constants must be defined so that it is known where to save the variables

rmpath(constants.lib_dir, constants.root_dir);

eyetrackerFcn('StopRecording');
eyetrackerFcn('CloseFile');

PsychPortAudio('Close', fb.handle);

ListenChar(0);
Priority(0);
sca; % alias for screen('CloseAll')
end
