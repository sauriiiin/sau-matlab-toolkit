%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  fit_stats.m

%   Author: Saurin Parikh, February 2018
%   dr.saurin.parikh@gmail.com


%%

    function data = fit_stats(table)
    
        connectSQL;
        inc.tt=1;
        hrs = fetch(conn, sprintf(['select distinct hours ',...
            'from %s'],table));
        
        for iii=1:length(hrs.hours)
            clear fit_dat;
            fit_dat = fetch(conn, sprintf(['select a.orf_name, a.hours, a.fitness ',...
                'from %s a ',...
                'where a.hours = %d ',...
                'and a.fitness is not NULL ',...
                'and a.orf_name != ''null'' and a.orf_name is not NULL ',...
                'order by a.orf_name asc'],table,hrs.hours(iii)));

            inc.t=1;
            for ii = 1 : (size(fit_dat.orf_name, 1))-1
                if(strcmpi(fit_dat.orf_name{ii, 1},fit_dat.orf_name{ii+1, 1})==1)
%                     temp(1, inc.t) = fit_dat.fitness(ii, 1);
                    temp(1, inc.t) = rmoutlier(fit_dat.fitness(ii, 1));
                    inc.t=inc.t+1;
                    if (ii == size(fit_dat.orf_name, 1)-1)
%                         temp(1, inc.t) = fit_dat.fitness(ii+1, 1);
                        temp(1, inc.t) = rmoutliers(fit_dat.fitness(ii+1, 1));
                        data.orf_name{inc.tt, 1} = fit_dat.orf_name{ii, 1};
                        data.hours(inc.tt, 1) = fit_dat.hours(ii, 1);
                        data.N(inc.tt, 1) = length(temp);
                        data.cs_mean(inc.tt, 1) = nanmean(temp);
                        data.cs_median(inc.tt, 1) = nanmedian(temp);
                        data.cs_std(inc.tt, 1) = nanstd(temp);
                        inc.tt=inc.tt+1;
                    end
                else
%                     temp(1, inc.t) = fit_dat.fitness(ii, 1);
                    temp(1, inc.t) = rmoutliers(fit_dat.fitness(ii, 1));
                    data.orf_name{inc.tt, 1} = fit_dat.orf_name{ii, 1};
                    data.hours(inc.tt, 1) = fit_dat.hours(ii, 1);
                    data.N(inc.tt, 1) = length(temp);
                    data.cs_mean(inc.tt, 1) = nanmean(temp);
                    data.cs_median(inc.tt, 1) = nanmedian(temp);
                    data.cs_std(inc.tt, 1) = nanstd(temp);
                    clear temp;
                    inc.t=1;
                    inc.tt=inc.tt+1;
                end
            end
        end
        conn(close);
    end


