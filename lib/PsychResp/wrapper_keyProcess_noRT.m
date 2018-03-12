function [response, press_time, exitFlag] = ...
    wrapper_keyProcess_noRT(keys_pressed, press_times)

% RT is always based on first key press

press_time = press_times(keys_pressed(1));

% exit flag and empty responses
switch keys_pressed(end)
    case KbName('Return')
        exitFlag = {'Return'};
        keys_forResp = keys_pressed(1:end-1);
        emptyResp = {'Return'};
    case KbName('Escape')
        exitFlag = {'ESCAPE'};
        keys_forResp = keys_pressed(1:end-1);
        emptyResp = {'Escape'};
    otherwise
        exitFlag = {'OK'};
        keys_forResp = keys_pressed;
        emptyResp = {''};
end

response = cleanResp(keys_forResp, keys_pressed, emptyResp);

end


function response = cleanResp(keys_forResp, keys_pressed, emptyResp)

% this will return empty matrix if not found
space_position = find(keys_pressed==KbName('space'));

% remove spaces so that they're not included in the response (KbName
% outputs the word 'space')
keys_forResp(space_position) = [];

% handle empty responses
if isempty(keys_forResp)
    response = emptyResp;
else
    response = {cell2mat(arrayfun(@(x) KbName(x), keys_forResp, 'UniformOutput',false))};
end

% if there were any spaces pressed, put them back in as actual spaces
if ~isempty(space_position)
    for space = 1:length(space_position)
        response{1} = [response{1}(1:space_position(space)-1), ' ',...
            response{1}(space_position(space):end)];
    end
end

end