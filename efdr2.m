%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  efdr2.m

%   Author: Saurin Parikh, August 2018
%   dr.saurin.parikh@gmail.com
%   
%   FDR(p) = (false positives based on p-value)/
%               (total significants for that p-value)

%%
    function out = efdr2(tablename_fit,tablename_pval,hours,contname,t)
    
        connectSQL;        
        out = [];
        dat = [];
        
        for iii = 1:length(hours)       
            pdat = fetch(conn, sprintf(['select * from %s ',...
                'where hours = %d and p != ''NULL'' ',...
                'and orf_name != ''%d'' ',...
                'order by orf_name asc'],tablename_pval,hours(iii),contname));
            
            
        end   
        conn(close);    
    end
    
    