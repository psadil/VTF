function keys = setupKeys( fMRI )

codes = zeros(1,256);
keys.escape = codes;
keys.escape(KbName('escape')) = 1;

keys.resp = codes;
keys.start = codes;

keys.resp(KbName({'1!'})) = 1; % decreased luminance
keys.robo_resp = '1!';
switch fMRI
    case true
        keys.start(KbName('5%')) = 1;
        keys.robo_start = '5%';
    case false
        keys.start(KbName({'space'})) = 1;
        keys.robo_start = '\SPACE';
end


end

