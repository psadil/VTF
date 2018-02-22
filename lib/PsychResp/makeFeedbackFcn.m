function fb_fnc = makeFeedbackFcn(give_feedback)


if give_feedback
    fb_fnc = @give_feedback_tone;
else
    fb_fnc = @do_nothing;
end

    function give_feedback_tone( handle, varargin )
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
        addParameter(ip,'duration', .1, @(x) isnumeric(x) && x >= 0);
        addParameter(ip,'sampling_rate', 44100, @(x) isnumeric(x));
        addParameter(ip,'startCue', 0, @islogical);   
        % Should we wait for the device to really start (1 = yes)
        addParameter(ip,'waitForDeviceStart', 0, @islogical);           
        parse(ip,varargin{:});
        input = ip.Results;
        
        
        % Start audio playback
        PsychPortAudio('Start', handle, [], input.startCue, input.waitForDeviceStart);
%         PsychPortAudio('Stop', handle, 1, 1);
        
    end

    function do_nothing(varargin)
        % do nothing with arguments
    end


end