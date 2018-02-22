function fb = setupFeedback( )

%feedback beeps
fb.correct_hz = 1000;
fb.incorrect_hz = 500;

fb.sampling_rate = 48000;

% Initialize Sounddriver
InitializePsychSound(0);

% Number of channels and Frequency of the sound
fb.n_channels = 2;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 0 = don't care about latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
fb.handle = PsychPortAudio('Open', [], 1, 0, fb.sampling_rate, fb.n_channels);

% Set the volume to half for this demo
PsychPortAudio('Volume', fb.handle, 0.5);

fb.duration = 0.1;

% Make a beep which we will play back to the user
fb.beep = MakeBeep(fb.incorrect_hz, fb.duration, fb.sampling_rate);

% Fill the audio playback buffer with the audio data, doubled for stereo
% presentation
PsychPortAudio('FillBuffer', fb.handle, [fb.beep; fb.beep]);


end

