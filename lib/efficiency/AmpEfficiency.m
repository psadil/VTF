%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Calculation ampliture Estimation efficiency
%    D-efficiency and A-efficiency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function optimality = AmpEfficiency(SPM, C, dFlag)

% design matrix convolved with hrf, mean centered. exclude the intercept
X = SPM.xX.X(:,1:end-1);

% autocorrelation to remove
V1 = SPM.xVi.Vi{1};
V2 = SPM.xVi.Vi{2};

% whitening filter
K = SPM.xX.K.X0;

% detrended and whitened design
IPvs = eye(size(K,1)) - ...
    ((V1 * inv(V1' * V1) * V1') * (V2 * inv(V2' * V2) * V2') * (K * inv(K' * K) * K'));
M = (X' * V1' * V2' * IPvs * V2' * V1' * X );

n_contrasts = size(C,1);
if dFlag
    optimality = det(C * M * C') ^ (1/n_contrasts);
else
    optimality = n_contrasts / trace(M);
end


return
