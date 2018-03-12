function dimming_data = setupDataDimming( constants )


dimming_data =  struct2table(tdfread(constants.data_dim_filename, 'tab'));


end
