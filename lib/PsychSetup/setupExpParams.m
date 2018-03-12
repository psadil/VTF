function expParams = setupExpParams( debugLevel, experiment, constants )


%% Defaults regardless of fMRI or debug level

data = struct2table(tdfread(constants.data_grating_filename, 'tab'));

switch experiment
    case 'contrast'
        
        
    case 'localizer'
        
        
end


expParams.n_trial = max(data.trial);

end
