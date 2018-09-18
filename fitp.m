%% Sau MATLAB Colony Analyzer Toolkit
%
%%  fitp.m

%   Author: Saurin Parikh, November 2017
%   dr.saurin.parikh@gmail.com

%   Calculates p-values from fitness data
%   pdata = fitp(cont, all)
%   cont.yield
%   all.orf_name, all.fitness
%   pdata.p, pdata.stats, pdata.orf_name

%%
    function pdata = fitp(cont, all)

    inc.t = 1;
    inc.tt = 1;

        for ii = 1 : (size(all.orf_name, 1))-1
            if(strcmpi(all.orf_name{ii, 1},all.orf_name{ii+1, 1})==1)
                temp(1, inc.t) = all.fitness(ii, 1);
                inc.t=inc.t+1;
                if (ii == size(all.orf_name, 1)-1)
                    temp(1, inc.t) = all.fitness(ii+1, 1); 
                    if(sum(isnan(temp))==length(temp))
                        pdata.p(inc.tt, 1) = NaN;
                        pdata.stat(inc.tt, 1) = NaN;
                    else
                        [p, h, stats] = ranksum(temp, cont.yield, 'alpha', 0.05, 'tail', 'both', 'method', 'approximate');
                        pdata.p(inc.tt, 1) = p;
                        pdata.stat(inc.tt, 1) = stats.zval;
                    end
                    pdata.orf_name{inc.tt, 1} = all.orf_name{ii, 1};
                    inc.tt=inc.tt+1;
                end
            else
                temp(1, inc.t) = all.fitness(ii, 1);
                if(sum(isnan(temp))==length(temp))
                    pdata.p(inc.tt, 1) = NaN;
                    pdata.stat(inc.tt, 1) = NaN;
                else
                    [p, h, stats] = ranksum(temp, cont.yield, 'alpha', 0.05, 'tail', 'both', 'method', 'approximate');
                    pdata.p(inc.tt, 1) = p;
                    pdata.stat(inc.tt, 1) = stats.zval;
                end
                pdata.orf_name{inc.tt, 1} = all.orf_name{ii, 1};
                clear temp;
                inc.t=1;
                inc.tt=inc.tt+1;
            end
        end
        
        pdata.p = num2cell(pdata.p);
        pdata.stat = num2cell(pdata.stat);
        pdata = orderfields(pdata, [3,1,2]);
        pdata.p(cellfun(@isnan,pdata.p)) = {[]};
        pdata.stat(cellfun(@isnan,pdata.stat)) = {[]};
end