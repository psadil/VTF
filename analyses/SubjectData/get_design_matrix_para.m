function [  ] = get_design_matrix_para( wd )

contrast_levels = [{'low'}, {'high'}];

matlabbatch{1}.spm.stats.fmri_design.dir = {wd};
matlabbatch{1}.spm.stats.fmri_design.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_design.timing.RT = 1.5;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t0 = 8;

for run = 1:8
    
    p = load(sprintf('MW_subNum1_allAttn_fMRI_Run%01d_Session1_Block1.mat', run));
    
    t = table(p.p.targOrient, p.p.tType,...
        (p.p.trialStart - p.p.startExp + p.p.cueExpose)',...
        (p.p.trialStart - p.p.startExp + p.p.cueExpose + p.p.stimDur / (p.p.ifi^-1) + p.p.delay / (p.p.ifi^-1))');
    
    bidsTable = table();
    bidsTable.onset = zeros(9*2*4,1);
    bidsTable.duration = zeros(9*2*4,1);
    bidsTable.trial_type = repelem({''},9*2*4)';

    cond = 0;
    for contrast = 1:2
        for orientation = 1:length(p.p.targOrients)
            cond = cond + 1;
            
            matlabbatch{1}.spm.stats.fmri_design.sess.nscan = 200;
            matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).name = ...
                strjoin([contrast_levels(contrast), num2str(p.p.targOrients(orientation))], '_');
            matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).onset = [t(t.Var1 == p.p.targOrients(orientation) & t.Var2 == contrast,:).Var3; ...
                t(t.Var1 == p.p.targOrients(orientation) & t.Var2 == contrast,:).Var4];
            matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).duration = p.p.stimDur / (p.p.ifi^-1);
            matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).tmod = 0;
            matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).orth = 1;
            
            nrows = length(matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).onset);
            bidsTable.onset(1+(cond-1)*nrows : (cond)*nrows) = matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).onset;
            bidsTable.duration(1+(cond-1)*nrows : (cond)*nrows) = repelem(matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).duration, nrows)';
            bidsTable.trial_type(1+(cond-1)*nrows : (cond)*nrows) = repelem({matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).name}, nrows)';
        end
    end
    %     writetable(t(:,1:2), 'tmp.txt', 'Delimiter',' ', 'WriteVariableNames', false)
    writetable(sortrows(bidsTable, 'onset'), sprintf('sub-01_task-con_run-%02d_events.tsv', run),...
        'Delimiter', 'tab', 'FileType', 'text');
    
    
    matlabbatch{1}.spm.stats.fmri_design.sess.multi = {''};
    matlabbatch{1}.spm.stats.fmri_design.sess.regress = struct('name', {}, 'val', {});
    matlabbatch{1}.spm.stats.fmri_design.sess.multi_reg = {''};
    matlabbatch{1}.spm.stats.fmri_design.sess.hpf = 128;
    
    matlabbatch{1}.spm.stats.fmri_design.fact = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_design.bases.fir.length = p.p.stimDur / (p.p.ifi^-1);
    matlabbatch{1}.spm.stats.fmri_design.bases.fir.order = 1;
    %     matlabbatch{1}.spm.stats.fmri_design.bases.hrf.derivs = [0 0];
    matlabbatch{1}.spm.stats.fmri_design.volt = 1;
    matlabbatch{1}.spm.stats.fmri_design.global = 'None';
    matlabbatch{1}.spm.stats.fmri_design.mthresh = 0.8;
    matlabbatch{1}.spm.stats.fmri_design.cvi = 'AR(1)';
    
    matlabbatch{2}.spm.stats.review.spmmat(1) = cfg_dep('fMRI model specification (design only): SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
    matlabbatch{2}.spm.stats.review.display.matrix = 1;
    matlabbatch{2}.spm.stats.review.print = 'ps';
    
    spm('defaults', 'FMRI');
    spm_jobman('run', matlabbatch);
    
    load('SPM.mat')
    
    X = array2table(SPM.xX.X);
    X = X(:,1:end-1);
    headers = extractfield(SPM.Sess.U, 'name');
    
    X.Properties.VariableNames = ...
        cellfun(@(x) matlab.lang.makeValidName(x), [headers{:}], 'UniformOutput', false);
    
    % rescale X to 0-1 before saving
    %     tmp = table2array(X);
    %     X{:, :} = X{:, :} / max(tmp(:));
    X{:,:} = X{:,:} > 0;
    writetable(X, sprintf('sub-01_task-con_run-%02d_design_fir.csv', run));
    
end


end
