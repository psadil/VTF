function qp = setupQParams(  )


% staircasing stuff only used for
% QUEST staircasing
% the params for the detection task
qp.delta=0.01; 
qp.gamma=0.5;
qp.beta=3.5;
qp.priorSd = 3;
qp.Correct_quest=0.75; 
qp.thresholdGuess_con=log10(.1);
qp.max_con = 1 - qp.contrast(2) + qp.maxJitterContrast;       % make sure we don't ever try to draw a stim with contrast > 1
qp.min_con = .01; % min=1 intensity unit

%initialize the contrast & orient params (these might be overridden later by the values from
%the previous block)
qp.cdThresh = qp.cChange;           % start contrast level 


% set up the quest staircases
qp.conq(1) = QuestCreate(qp.thresholdGuess_con, qp.priorSd, p.Correct_quest,...
    qp.beta, qp.delta, qp.gamma, qp.min_con, 3);
qp.conq(2) = QuestCreate(qp.thresholdGuess_con, qp.priorSd, p.Correct_quest,...
    qp.beta, qp.delta, qp.gamma, qp.min_con, 3);


end
