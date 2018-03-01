%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Calculation ampliture Estimation efficiency
%    D-efficiency and A-efficiency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function optimality = AmpEfficiency(SPM, C, dFlag)

% design matrix convolved with hrf, mean centered. exclude the intercept
X = SPM.xX.X;
n_scans = size(X,1);

% autocorrelation to remove (AR(1) process, assuming rho=.3)
V = spm_Q(.3, n_scans, 0);

% frequency confounds
S = SPM.xX.K.X0;

% apply autocorrelation and remove fequency confounds
% IPvs = eye(n_scans) - ((V / (V' * V) * V') * (S / (S' * S) * S'));
% M = C * ((X' * V' * IPvs * V * X ) \ C');

IPvs = V * S * ((S' * V' * V * S) \ (S' * V') );
% IPvs = VS * pinv(VS' * VS) * VS' ;
M = C * ((X' * V' * (eye(n_scans) - IPvs) * V * X) \ C');
% M = C * pinv(X' * V' * (eye(n_scans) - IPvs) * V * X) * C';

n_contrasts = size(C,1);
if dFlag
    optimality = det(M) ^ (1/n_contrasts);
else
    optimality = n_contrasts / trace(M);
end


return
