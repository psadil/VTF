%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Calculation ampliture Estimation efficiency
%    D-efficiency and A-efficiency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function optimality = AmpEfficiency(SPM, C, optimality)

% design matrix convolved with hrf, mean centered. exclude the intercept
X = SPM.xX.X;
n_scans = size(X,1);

% autocorrelation to remove (AR(1) process, assuming rho=.3)
V = spm_Q(.3, n_scans, 0);

% frequency confounds
S = SPM.xX.K.X0;

% apply autocorrelation and remove fequency confounds
P_vs = V * S * ((S' * V' * V * S) \ (S' * V') ); %#ok<MHERM>
M = C * ((X' * V' * (eye(n_scans) - P_vs) * V * X) \ C');

n_contrasts = size(C,1);

switch optimality
    case 'D'
        optimality = det(M) ^ (1/n_contrasts);
    case 'A'
        optimality = n_contrasts / trace(M);
end

return
