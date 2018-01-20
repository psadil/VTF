%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Calculation ampliture Estimation efficiency
%    D-efficiency and A-efficiency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function AmpEff = AmpEfficiency(X, C, dflag)
%
% calcuation of D- or A-efficiency for amplitude estimation
% Inputs:
%   deconvM: deconvoluted Matrix
%   defHRF: assumed shape of HRF
%   numSTYPE: number of active stimulus types
%   WhitenM: whitening matrix
%   Ctrst: contrast
%   dflag: which efficiency to use: 1=D-optimality; 0=A-optimality

% Output:
%   AmpEff: estimation efficiency

p = size(C,1);
X2 = X'*X;
if (rcond(X2) > eps) 
    invM = inv(X2);
    if dflag %D-opt
        AmpEff = det(C * invM * C')^(-1/p);
    else     %A-opt
        AmpEff = p/trace(C * invM * C');
    end
else
    AmpEff = 0; % when X is (near-)singular
end

return
