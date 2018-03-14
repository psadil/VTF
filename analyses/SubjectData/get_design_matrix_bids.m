clearvars

% this script seems to be able to take sub-01's .mat file and produce a
% bids compatable .*events.tsv file. 

contrast_levels = [{'low'}, {'high'}];

bidsTable = table();
bidsTable.onset = zeros(9*2*4,1);
bidsTable.duration = zeros(9*2*4,1);
bidsTable.trial_type = repelem({''},9*2*4)';


for run = 1:8
    
    p = load(sprintf('MW_subNum1_allAttn_fMRI_Run%01d_Session1_Block1.mat', run));
    
    t = table(p.p.targOrient, p.p.tType,...
        (p.p.trialStart - p.p.startExp + p.p.cueExpose)',...
        (p.p.trialStart - p.p.startExp + p.p.cueExpose + p.p.stimDur / (p.p.ifi^-1) + p.p.delay / (p.p.ifi^-1))');
    
    cond = 0;
    for contrast = 1:2
        for orientation = 1:length(p.p.targOrients)
            cond = cond + 1;
            
            
            nrows = length( [t(t.Var1 == p.p.targOrients(orientation) & t.Var2 == contrast,:).Var3; ...
                t(t.Var1 == p.p.targOrients(orientation) & t.Var2 == contrast,:).Var4]);
            
            bidsTable.onset(1+(cond-1)*nrows : (cond)*nrows) = ...
                [t(t.Var1 == p.p.targOrients(orientation) & t.Var2 == contrast,:).Var3; ...
                t(t.Var1 == p.p.targOrients(orientation) & t.Var2 == contrast,:).Var4];
            bidsTable.duration(1+(cond-1)*nrows : (cond)*nrows) = repelem(p.p.stimDur / (p.p.ifi^-1), nrows)';
            bidsTable.trial_type(1+(cond-1)*nrows : (cond)*nrows) = ...
                repelem({strjoin([contrast_levels(contrast), num2str(p.p.targOrients(orientation))], '_')}, nrows)';
        end
    end
    
    writetable(sortrows(bidsTable, 'onset'), sprintf('sub-01_task-con_run-%02d_events_pre.tsv', run), 'Delimiter', 'tab', 'FileType', 'text');
    
end
