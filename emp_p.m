%% Sau MATLAB Colony Analyzer Toolkit
%
%%  emp_p.m

%   Author: Saurin Parikh, September 2018
%   dr.saurin.parikh@gmail.com

%   Calculates emperical p-value from fitness data
%   out = emp_p(tablename_fit,tablename_fits,hours,contname, n)
%
%   Need to add stats

%%
    function out = emp_p(tablename_fit,tablename_fits,hours,contname, n)
    
        connectSQL;
        for iii = 1:length(hours)
            contfit = fetch(conn, sprintf(['select fitness from %s ',...
                'where hours = %d and orf_name = ''%s'' ',...
                'and fitness is not null'],tablename_fit,hours(iii),contname));
            
            contmean = nanmean(contfit.fitness);
            contstd = nanstd(contfit.fitness);

            orffit = fetch(conn, sprintf(['select orf_name, cs_median, ',...
                'cs_mean, cs_std from %s ',...
                'where hours = %d and orf_name != ''%s'' ',...
                'order by orf_name asc'],tablename_fits,hours(iii),contname));

            m = [];
            tt = 100000;
            for ii = 1:tt
                [temp, ~] = datasample(contfit.fitness, n);
                m = [m; median(temp)];
            end
    %         histogram(m);

            pvals = [];
            stat = [];
            for i = 1:length(orffit.orf_name)
                if sum(m<orffit.cs_median(i)) < tt/2
                    if m<orffit.cs_median(i) == 0
                        pvals = [pvals; 1/tt];
                        stat = [stat; (orffit.cs_mean(i) - contmean)/contstd];
                    else
                        pvals = [pvals; sum(m<=orffit.cs_median(i))/tt];
                        stat = [stat; (orffit.cs_mean(i) - contmean)/contstd];
                    end
                else
                    pvals = [pvals; sum(m>=orffit.cs_median(i))/tt];
                    stat = [stat; (orffit.cs_mean(i) - contmean)/contstd];
                end
            end

            out{iii}.orf_name = orffit.orf_name;
            out{iii}.hours = ones(length(out{iii}.orf_name),1)*hours(iii);
            out{iii}.p = num2cell(pvals);
            out{iii}.p(cellfun(@isnan,out{iii}.p)) = {[]};
            out{iii}.stat = num2cell(stat);
            out{iii}.stat(cellfun(@isnan,out{iii}.stat)) = {[]};

        end
        conn(close);
    end
    
    