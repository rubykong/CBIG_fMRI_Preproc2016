function output = trendout(input)

[n,ncol] = size(input);

x = zeros(n,1);
for i=0:(n-1)
    x(i+1) = -1+2*i/(n-1);
end
sxx = n*(n+1)/(3*(n-1));
sy = sum(input);
sxy = sum(bsxfun(@times,input,x));

a0 = sy/n;
a1 = sxy/sxx;
output = input - x*a1;
