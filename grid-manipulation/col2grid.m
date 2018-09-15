%% Sau MATLAB Colony Analyzer Toolkit
%
%% col2grid.m
%
% Author: Saurin Parikh, August, 2017
% dr.saurin.parikh@gmail.com
%
% The col2grid function transforms the standard 1xn colsizes matrix from
% the analyze_image function in a pxq matrix depending on the original grid
% density.
%
% v1.0 density options - 96, 1536
% v2.0 all density options
% v2.1 doesn't need the 'shape' entry any more

%%
function output = col2grid(colsizes)

shape = length(colsizes);
a = sqrt(shape/96);

output = [];

i = 1;
ii = 1;
n = 1;

    while i <= 12*a
        while ii <= 8*a
            output(ii, i) = colsizes(n);
            ii = ii + 1;
            n = n + 1;
        end
        ii = 1;
        i = i + 1;
    end




