%% Sau MATLAB Colony Analyzer Toolkit
%
%% grid2row.m
%
% Author: Saurin Parikh, August, 2017
% dr.saurin.parikh@gmail.com
% 
% Convert grid into a single row. To be used after grid manipulations like
% boundary elimination (elibound) etc.
% Gives the same output as colsizes from load_colony_size.


%%
function output = grid2row(data)

[row, col] = size(data);

output = [];
i = 1;

while i <= col
    output = [output, transpose(data(:,i))];
    i = i + 1;
end

