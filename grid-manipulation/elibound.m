%% Sau MATLAB Colony Analyzer Toolkit
%
%% elibound.m
%
% Author: Saurin Parikh, August, 2017
% dr.saurin.parikh@gmail.com
%
% Eliminate boundary colonies in raw data before normalization using this
% function.
% Can be used to evaluate the effect of normalization on the data and
% compare pre-post effects.
%
% Utilizes results form col2grid function in the sau-matlab-toolkit.
%
%%

function output = elibound(data, n)

% data is the output from col2grid function
% n is the number boundaries to be removed

[r, ~] = size(data);

if r == 1
    data = col2grid(data);
    [row, col] = size(data);
    output = data(1+n:row-n, 1+n:col-n);
else
    [row, col] = size(data);
    output = data(1+n:row-n, 1+n:col-n);
end
