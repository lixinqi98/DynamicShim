% solveDC.m
% Solve the lsqlin using B0 and Bz within the predicted
% segmentation
% parameters:
%   B0: frequency map(Hz), (H, W, slices)
%   Bzf: flatten Bz field, (H*W, #coils)
%   seg: predicted segmentation, (H, W, slices)
%   DC_limit: current limit, (A)
function [DC] = solveDC(B0, Bzf, seg, DC_limit)

    B0f_seg = double(B0(seg)); 
    Bzf_seg = Bzf(seg(:),:);
    [~,nc] = size(Bzf_temp);
    lb0 = -ones(nc,1)*DC_limit;  %lower bound  dc limit
    ub0 = ones(nc,1)*DC_limit;   % upper bound dc limit 
    X0 = zeros(nc,1);                 % initial value, 0

    options7 = optimset('Algorithm','trust-region-reflective','MaxFunEvals',1e14, 'MaxIter',...
        1e12,'TolFun',1e-20,'TolX',1e-16,'Disp','off');%,'Largescale','off',);
    [X,resnorm,residual] = lsqlin(Bzf_seg,B0f_seg,[],[],[],[],lb0,ub0,X0,options7);
    %     X = mldivide(Bzf,B0f);
    DC = reshape(X,[nc 1]); % in (A)
end

