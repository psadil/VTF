
function model = DconvMTX(stim_list, n_scan, n_stimtype, epoch_length, TR)
%
% Generate the convolved model matrix

nStims = length(stim_list);
scan_time = TR * n_scan;
onsets = generate_onsets2(nStims, epoch_length, scan_time);

matlabbatch{1}.spm.stats.fmri_design.dir = {'D:\git\fMRI\VTF\lib\efficiency'};
matlabbatch{1}.spm.stats.fmri_design.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_design.timing.RT = TR;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t = 16;
matlabbatch{1}.spm.stats.fmri_design.timing.fmri_t0 = 8;
matlabbatch{1}.spm.stats.fmri_design.sess.nscan = n_scan;

for cond = 1:n_stimtype    
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).name = num2str(cond);
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).onset = onsets(stim_list==cond);
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).duration = epoch_length;
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).tmod = 0;
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).pmod = struct('name', {}, 'param', {}, 'poly', {});
    matlabbatch{1}.spm.stats.fmri_design.sess.cond(cond).orth = 1;
end

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
% % spm_jobman('run', matlabbatch);
% spm = spm_fmri_spm_ui(SPM, 0);

% load('SPM.mat')
model = SPM.xX.X;
% delete('SPM.mat')

end
