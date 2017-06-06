function fb = setupFeedback( fMRI )


%feedback beeps
dur = .1; % in sec
fb.sr = 44100; %sampling rate
samp = 0:1/fb.sr:dur;

switch fMRI
    case false
        fb.cor = sin(2*pi*samp*1000); %1000 Hz
        fb.incor = sin(2*pi*samp*3000); %3000 Hz
        
    case true
        fb.cor = []; %1000 Hz
        fb.incor = []; %3000 Hz
        
end

end

