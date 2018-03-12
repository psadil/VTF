function data = setupDataTable( expParams, subject, experiment, constants )

switch experiment
    case 'contrast'
        
        data = struct2table(tdfread(constants.data_grating_filename, 'tab'));
        data.orientation = str2num(data.orientation); %#ok<ST2NM>
        data.contrast = str2num(data.contrast); %#ok<ST2NM>
        
    case 'localizer'
        
        data = struct2table(tdfread(constants.data_grating_filename, 'tab'));
        data.orientation = str2num(data.orientation); %#ok<ST2NM>
        data.contrast = str2num(data.contrast); %#ok<ST2NM>
        
end


end
