%% Sau MATLAB Colony Analyzer Toolkit
%
%%  emp_p.m

%   Author: Saurin Parikh, September 2018
%   dr.saurin.parikh@gmail.com

%   Calculates emperical p-value from fitness data
%   out = emp_p(tablename_fit,tablename_fits,hours,contname, n)

%%
    function out = emp_p(tablename_fit,tablename_fits,hours,contname, n)
    
    connectSQL;
        
    for iii = 1:length(hours)
        contfit = fetch(conn, sprintf(['select fitness from %s ',...
            'where hours = %d and orf_name = ''%s'' ',...
            'and fitness is not null'],tablename_fit,hours(iii),contname));
        
        orffit = fetch(conn, sprintf(['select orf_name, cs_median from %s ',...
            'where hours = %d and orf_name != ''%s'' ',...
            'order by orf_name asc'],tablename_fits,hours(iii),contname));
        
        m = [];
        for ii = 1:20000
            [temp, ~] = datasample(contfit.fitness, n);
            m = [m; median(temp)];
        end
%         histogram(m);

        pvals = [];
        for i = 1:length(orffit.orf_name)
            if sum(m<orffit.cs_median(i)) < 10000
                pvals = [pvals; sum(m<orffit.cs_median(i))/20000];
            else
                pvals = [pvals; sum(m>orffit.cs_median(i))/20000];
            end
        end
        
        out{iii}.orf_name = orffit.orf_name;
        out{iii}.hours = ones(length(out{iii}.orf_name),1)*hours(iii);
        out{iii}.p = num2cell(pvals);
        out{iii}.p(cellfun(@isnan,out{iii}.p)) = {[]};
        
    end
    
    conn(close);
   
    end
    
    