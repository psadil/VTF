function give_feedback_tone( frequency, varargin )
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

%%

% parse inputs, apply defaults
ip = inputParser;
addParameter(ip,'duration', .1, @(x) isnumeric(x) && x >= 0);
addParameter(ip,'sampling_rate', 44100, @(x) isnumeric(x));
parse(ip,varargin{:});
input = ip.Results;

% create sample to play
sample = 0:1/input.sampling_rate:input.duration;

% convert to sin wave according to frequency
beep = sin(2 * pi * sample * frequency);

% play sound
sound(beep, input.sampling_rate)

end

