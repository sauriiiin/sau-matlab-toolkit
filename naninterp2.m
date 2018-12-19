%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  naninterp2.m

%   Author: Saurin Parikh, December 2018
%   dr.saurin.parikh@gmail.com

%   Some of the original points may have x values outside the range of the
%   resampled data.  Those are now NaN because we could not interpolate them.
%   Replace NaN by the closest interpolated value.

%%
    function ys = naninterp2(x,y,p,xq,yq,method)
    
    if nargin<6 || isempty(method)
        method = 'linear';
    end
    
    % Interpolate to evaluate this at the xq, yq values
    ys = interp2(x,y,p,xq,yq,method);
    % Fill the NaNs with the nearest values
    ys = fillmissing(fillmissing(ys, 'nearest',2),'nearest',1);
    
    end

    