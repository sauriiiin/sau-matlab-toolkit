%% Sau MATLAB Colony Analyzer Toolkit
%
%% coloutlier.m
%
% Author: Saurin Parikh, August, 2017
% dr.saurin.parikh@gmail.com
% 
% Inputs = Colony grids (outputs from col2grid) function
% ouput = [row, col, colony size 1 value, colony size 2 value]
% therfore, output has location and value of those corresponding 
% colonies whose differences in size are outliers.
%
% mnsizes = mean of the size differences
% outsd = 2 * standard deviation of the size differences
%
% Useful to identify differential effect of plate conditions

%%
function [output, mnsizes, outsd] = coloutlier(data1, data2)

output = [];
[row, ~] = size(data1);
i = 1;

if size(data1) == size(data2)
    data11 = grid2row(data1);
    data22 = grid2row(data2);
    
    diffsizes = data11 - data22;
    mnsizes = mean(diffsizes);
    sdsizes = std(diffsizes);
    
    outsd = 2 * sdsizes;
    
   while i <= length(diffsizes)
       if diffsizes(1, i) > mnsizes + outsd || diffsizes(1, i) < mnsizes - outsd
          if rem(i,row) == 0
              output = [output; [row, ceil(i/row), ...
                  data1(row, ceil(i/row)), ...
                  data2(row, ceil(i/row))]];
          else
              output = [output; [rem(i,row), ceil(i/row), ...
                  data1(rem(i,row), ceil(i/row)), ...
                  data2(rem(i,row), ceil(i/row))]];
               % ceil(i/row) = original column in grid
               % rem(i/row) = original row in grid
          end
       else
           output;
       end
       i = i + 1;
   end
   i = 1;
end