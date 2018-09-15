%% Sau MATLAB Colony Analyzer Toolkit
%
%% medbound.m
%
% Author: Saurin Parikh, September, 2017
% dr.saurin.parikh@gmail.com
%
% Instead of eliminating the boundary colonies we replace the boundary
% values with the median of the rest of the plate.
% 
% eg if you want to avoid the outer 2 borders then this function will
% replace the outer 2 borders with median of everything but the outer two
% colony sizes.
%
% Can be used to evaluate the effect of normalization on the data and
% compare pre-post effects.
%
% Utilizes results form col2grid function in the sau-matlab-toolkit.
%
%%

function output = medbound(data, n)

% data is the output from col2grid function
% n is the number boundaries to be removed

[r, ~] = size(data);

if r == 1
    data = col2grid(data);
    [row, col] = size(data);
    eli = elibound(data,n);
    med = nanmedian(eli(:));
    data(:,1) = med;    % right
    data(:,end) = med;  % left
    data(1,:) = med;    % top
    data(end,:) = med;  % bottom
    output = grid2row(data);
else
    [row, col] = size(data);
    eli = elibound(data,n);
    med = nanmedian(eli(:));
    data(:,1) = med;    % right
    data(:,end) = med;  % left
    data(1,:) = med;    % top
    data(end,:) = med;
    output = data;
end
