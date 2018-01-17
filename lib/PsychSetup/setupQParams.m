function qp = setupQParams( delta_luminance_guess )

% staircasing stuff only used for
% QUEST staircasing
% the params for the detection task
delta = 0.01; 
gamma = 0.5;
beta = 3.5;
tGuessSd = 3;
pThreshold = 0.75; 
tGuess_luminance_change = log10(delta_luminance_guess); 
grain = 0.05;
range = 100;


% set up the quest staircases
qp = QuestCreate(tGuess_luminance_change, tGuessSd, pThreshold,beta, delta, gamma, grain, range);

% variables to restrict range of drawn luminance. Note that these are not
% used by Quest directly, but instead limits imposed while drawing stimuli
% that quest suggests
qp.max_luminance = 0.98; 
qp.min_luminance = .02; 

end
