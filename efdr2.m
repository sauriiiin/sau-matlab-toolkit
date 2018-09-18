%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  efdr2.m

%   Author: Saurin Parikh, August 2018
%   dr.saurin.parikh@gmail.com
%   
%   FDR(p) = (false positives based on p-value)/
%               (total significants for that p-value)

%%
    function pdat = efdr2(tablename_pval,hours,contname)
        connectSQL;        
        dat = [];
        for iii = 1:length(hours)       
            pdat{iii} = fetch(conn, sprintf(['select * from %s ',...
                'where hours = %d and p != ''NULL'' ',...
                'and orf_name != ''%s'' ',...
                'order by orf_name asc'],tablename_pval,hours(iii),contname));
            for ii = 1:length(pdat{iii}.orf_name)
                dat = [dat;...
                    (pdat{iii}.p(ii)*length(pdat{iii}.orf_name))/sum(pdat{iii}.p<pdat{iii}.p(ii))];
            end
            pdat{iii}.efdr = dat;
        end   
        conn(close);    
    end
    
    