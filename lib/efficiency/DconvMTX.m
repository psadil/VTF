function SPM = DconvMTX(stim_list, n_scan, n_stimtype, epoch_length, TR, onsets, dim_dur)
%
% Generate the convolved model matrix


matlabbatch{1}.spm.stats.fmri_design.dir = {'D:\git\fMRI\VTF\lib\efficiency'};
matlabbatch{1}.spm.stats.fmri_design.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_design.timing.RT = TR;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t0 = 8;
matlabbatch{1}.spm.stats.fmri_design.sess.nscan = n_scan;

for cond = 1:n_stimtype    
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).name = num2str(cond);
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).onset = onsets(stim_list==cond);
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).duration = epoch_length(stim_list==cond);
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).orth = 1;
end
matlabbatch{1}.spm.stats.fmri_design.sess.cond(n_stimtype+1).name = 'dimming';
matlabbatch{1}.spm.stats.fmri_design.sess.cond(n_stimtype+1).onset = onsets(stim_list == 99);
matlabbatch{1}.spm.stats.fmri_design.sess.cond(n_stimtype+1).duration = dim_dur;
matlabbatch{1}.spm.stats.fmri_design.sess.cond(n_stimtype+1).tmod = 0;
matlabbatch{1}.spm.stats.fmri_design.sess.cond(n_stimtype+1).pmod = struct('name', {}, 'param', {}, 'poly', {});
matlabbatch{1}.spm.stats.fmri_design.sess.cond(n_stimtype+1).orth = 1;

matlabbatch{1}.spm.stats.fmri_design.sess.multi = {''};
matlabbatch{1}.spm.stats.fmri_design.sess.regress = struct('name', {}, 'val', {});
matlabbatch{1}.spm.stats.fmri_design.sess.multi_reg = {''};
matlabbatch{1}.spm.stats.fmri_design.sess.hpf = 128;
matlabbatch{1}.spm.stats.fmri_design.fact = struct('name', {}, 'levels', {});
matlabbatch{1}.spm.stats.fmri_design.bases.hrf.derivs = [1 1];
matlabbatch{1}.spm.stats.fmri_design.volt = 1;
matlabbatch{1}.spm.stats.fmri_design.global = 'None';
matlabbatch{1}.spm.stats.fmri_design.mthresh = 0.8;
matlabbatch{1}.spm.stats.fmri_design.cvi = 'AR(1)';

SPM  = spm_run_fmri_spec2(matlabbatch{1}.spm.stats.fmri_design);

end
