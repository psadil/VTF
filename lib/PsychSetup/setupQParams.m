function qp = setupQParams(  )

% staircasing stuff only used for
% QUEST staircasing
% the params for the detection task
qp.delta = 0.01; 
qp.gamma = 0.5;
qp.beta = 3.5;
qp.tGuessSd = 3;
qp.pThreshold = 0.75; 
qp.tGuess_luminance = log10(.1);
qp.grain = 0.05;
qp.range = 3;

% variables to restrict range of drawn luminance. Note that these are not
% used by Quest directly, but instead limits imposed while drawing stimuli
% that quest suggests
qp.max_luminance = 0.95; 
qp.min_luminance = .05; 


%initialize the contrast & orient params (these might be overridden later by the values from
%the previous block)
qp.cdThresh = qp.cChange;           % start contrast level 

% set up the quest staircases
qp.conq = QuestCreate(qp.tGuess_luminance, qp.tGuessSd, p.pThreshold,...
    qp.beta, qp.delta, qp.gamma, qp.grain, qp.range);

end
