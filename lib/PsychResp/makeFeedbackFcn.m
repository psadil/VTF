function [fb_fnc, fb] = makeFeedbackFcn(give_feedback)

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


if give_feedback
    fb_fnc = @give_feedback_tone;
else
    fb_fnc = @do_nothing;
end

    function give_feedback_tone( varargin )
        % play single note for feedback during experiment
        
        %{

REQUIRED INPUT:
  frequency: frequency of tone to play (default: NaN)

OPTIONAL INPUT:
  duration: length in seconds of tone (default: .1)
  sampling_rate: can change fidelity of sound (default: 44100). Never
    really need to mess with, more important for complex sounds. See
    https://www.mathworks.com/help/dsp/examples/audio-sample-rate-conversion.html
    https://www.mathworks.com/help/signal/ug/changing-signal-sample-rate.html

OUTPUT:
  Does not return anything, but plays tone according to input

EXAMPLE CALL
  - For lower beep:
    give_feedback_tone(1000);
  
  - Higher beep:
    give_feedback_tone(3000);

  - Longer beep:
    give_feedback_tone('frequency', 1000, 'duration', .5);

        %}
        
        % parse inputs, apply defaults
        ip = inputParser;
        
        % duration probably ought to be less than flip rate
        addParameter(ip,'duration', .05, @(x) isnumeric(x) && x >= 0);
        addParameter(ip,'sampling_rate', 44100, @(x) isnumeric(x));
        addParameter(ip,'startCue', 0, @islogical);
        % Should we wait for the device to really start (1 = yes)
        addParameter(ip,'waitForDeviceStart', 0, @islogical);
        parse(ip,varargin{:});
        input = ip.Results;
        
        % Start audio playback
        PsychPortAudio('Start', fb.handle, [], input.startCue, input.waitForDeviceStart);
        %         PsychPortAudio('Stop', handle, 1, 1);
        
    end

    function do_nothing(varargin)
        % do nothing with arguments
    end


end