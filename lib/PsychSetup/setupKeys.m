function keys = setupKeys( fMRI )


codes = zeros(1,256);
keys.escape = codes;
keys.escape(KbName('escape')) = 1;


keys.resp = codes;
keys.start = codes;
switch fMRI
    case true
        keys.resp(KbName({'1!'})) = 1; % decreased luminance
        keys.start(KbName('5%')) = 1;

    case false
        keys.resp(KbName({'DownArrow'})) = 1; % decreased luminance
        keys.start(KbName({'space'})) = 1;
end


end

