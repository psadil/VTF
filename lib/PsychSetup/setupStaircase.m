function stairs = setupStaircase( delta_luminance_guess )


% these are the luminance changes to consider
stairs.options = (0.1:.01:.6)';
stairs.first_trial = delta_luminance_guess;

stairs.luminance_difference = stairs.first_trial;

end
