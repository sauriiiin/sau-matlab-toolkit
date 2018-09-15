%% Sau MATLAB Colony Analyzer Toolkit
%
%%  downscale.m
%   
%   Author: Saurin Parikh, October, 2017
%   dr.saurin.parikh@gmail.com
%   
%   Generates four lower density plate using one high density plates.
%   
%   (topleft, topright, bottomleft, bottomright) = downscale(plate)
%%

function [tl, tr, bl, br] = downscale(plate)

    [~, c] = size(plate);
    
%   divide into two matrix columnwise
    
    i = 1;
    templ = []; tempr = [];
    tl = []; bl = []; tr = []; br = []; 
    
    while i <= c
        if rem(i,2) == 1
            templ = [templ, plate(:,i)];
        else
            tempr = [tempr, plate(:,i)];
        end
        i = i + 1;
    end
    
%   now divide into two matrix rowwise    
    i = 1;
    [r, ~] = size(templ);
    
    while i <= r
        if rem(i,2) == 1
            tl = [tl; templ(i,:)];
            tr = [tr; tempr(i,:)];
        else
            bl = [bl; templ(i,:)];
            br = [br; tempr(i,:)];
        end
        i = i + 1;
    end
end
    
        