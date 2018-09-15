%% Sau MATLAB Colony Analyzer Toolkit
%
%% wherezero.m
%
% Author: Saurin Parikh, August, 2017
% dr.saurin.parikh@gmail.com
% 
% Inputs = Colony grids (outputs from col2grid) function
% ouput = Locations of colonies that exist in one plate but are absent from
% the other. 
% Everything before the [0,0] are locations on input1 which do not have a colony
% but there is a colony present in input2. Everything after [0,0] indicates
% the other way round.

%%
function output = wherezero(data1, data2)

output = [];
[r, ~] = size(data1);
i = 1;
j = 1;

if size(data1) == size(data2);
    
    if r == 1
        data1 = data1;
        data2 = data2;
        [row, ~] = size(col2grid(data1));
    else
        [row, ~] = size(data1);
        data1 = grid2row(data1);
        data2 = grid2row(data2);
    end
    
   
    
   while i <= length(data1);
       if data1(1, i) == 0;
           if data2(1, i) == 0;
               output = output;
           else data2(1, i) > 0;
               if rem(i,row) == 0
                   output = [output; [row, ceil(i/row)]];
               else
                   output = [output; [rem(i,row), ceil(i/row)]];
               end
               % ceil(i/row) = original column in grid
               % rem(i/row) = original row in grid
           end
       else
           output;
       end
       i = i + 1;
   end
   output = [output; [0,0]];
   
   while j <= length(data1);
       if data2(1, j) == 0;
           if data1(1,j) == 0;
               output = output;
           else data2(1, j) > 0;
               if rem(j,row) == 0
                   output = [output; [row, ceil(j/row)]];
               else
                   output = [output; [rem(j,row), ceil(j/row)]];
               end
           end
       else
           output;
       end
       j = j + 1;
   end
   i = 1;
   j = 1;
end