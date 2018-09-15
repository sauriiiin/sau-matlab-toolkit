%% Sau MATLAB Colony Analyzer Toolkit
%
%%  detect_den.m
%   
%   Author: Saurin Parikh, November, 2017
%   dr.saurin.parikh@gmail.com

%   Detect density of the plate based on the dimensions used for analysis

%%

function [n_plate, density] = detect_den(dimensions, vector)
    
  if dimensions == [64 96]
      density = 6144;
      n_plate = length(vector)/6144;
  elseif dimensions == [32 48]
      density = 1536;
      n_plate = length(vector)/1536;
  else
      density = 384;
      n_plate = length(vector)/384;
  end
end