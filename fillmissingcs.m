%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  fillmissingcs.m

%   Author: Saurin Parikh, May 2019
%   dr.saurin.parikh@gmail.com

%   fillmissing using cubic spline

%%
    function out = fillmissingcs(in)
        warning('off','all')
        [row, col] = size(in);
        temp_cc = [];
        temp_rr = [];
        for cc=1:col
            if sum(~isnan(in(:,cc))) < 2
                temp_cc(:,cc) = zeros(1,row);
            else
                temp_cc(:,cc) = interp1(1:row,in(:,cc),1:row,'spline');
            end               
        end
        
        for rr=1:row
            if sum(~isnan(in(rr,:))) < 2
                temp_rr(rr,:) = zeros(1,col);
            else
                temp_rr(rr,:) = interp1(1:col,in(rr,:),1:col,'spline');
            end               
        end
        out = (temp_rr + temp_cc)/2;
        warning('on','all')
    end