
%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  fitq2.m

%   Author: Saurin Parikh, September 2018
%   dr.saurin.parikh@gmail.com

%   Calculates q value and fdr from p values
%   qdata = fitq(allp)

%%
    function qdata = fitq2(allp)
    
        qdata.orf_name = [];
        qdata.q = [];
        qdata.p = [];
        qdata.stat = [];

        if (strcmpi(allp, 'No Data')~=1)
            [fdr, qy]               = mafdr(allp.p);
            [pvals.y, pvals.ypos]   = sort(qy);
            pp.y                    = size(pvals.y);

            qdata.orf_name          = allp.orf_name(pvals.ypos(1:pp.y));
            qdata.q                 = pvals.y(1:pp.y);
            qdata.fdr               = fdr(pvals.ypos(1:pp.y));
            qdata.p                 = allp.p(pvals.ypos(1:pp.y));
            qdata.stat              = allp.stat(pvals.ypos(1:pp.y));

        end
        
        qdata.q     = num2cell(qdata.q);
        qdata.fdr   = num2cell(qdata.fdr);
        qdata.p     = num2cell(qdata.p);
        qdata.stat  = num2cell(qdata.stat);
        qdata.q(cellfun(@isnan,qdata.q)) = {[]};
        qdata.fdr(cellfun(@isnan,qdata.fdr)) = {[]};
        qdata.p(cellfun(@isnan,qdata.p)) = {[]};
        qdata.stat(cellfun(@isnan,qdata.stat)) = {[]};
    end
    
    