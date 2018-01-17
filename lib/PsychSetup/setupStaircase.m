function stairs = setupStaircase( delta_luminance_guess, nTrials )


% these are the luminance changes to consider
stairs.options = (0.05:.05:.6)';
stairs.first_trial = delta_luminance_guess;
stairs.correct = NaN([nTrials,1]);
stairs.luminance_difference = NaN([nTrials,1]);

stairs.luminance_difference(1) = stairs.first_trial;

end
