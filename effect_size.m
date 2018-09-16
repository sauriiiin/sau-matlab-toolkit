%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  effect_size.m

%   Author: Saurin Parikh, February 2018
%   dr.saurin.parikh@gmail.com

%   Effect Size calculator based on fitness data

%%
    function [es, n] = effect_size(cont_n, cont_avg, cont_std,...
        orf_n, orf_avg, orf_std,...
        z_sig, z_pow)
    
        std = (((cont_n-1)*(cont_std).^2 + (orf_n-1).*(orf_std).^2)/(cont_n+orf_n-2)).^(0.5);
        es = abs(cont_avg-orf_avg)/std;
        n = ceil((((z_sig+z_pow)/es).^2)*1.15);
    
    end