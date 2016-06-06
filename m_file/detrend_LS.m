function [resid,retrend_mtx] = detrend_LS(Y)
[r,c]=size(Y);
x=linspace(-1,1,r)';
X=[ones(r,1) x];
b = (X'*X)\(X'*Y);
resid = Y-X*b;
retrend_mtx = X*b;
