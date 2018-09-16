%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  empfdr.m

%   Author: Saurin Parikh, April 2018
%   dr.saurin.parikh@gmail.com
    

%%
    function out = empfdr(tablename_fit,tablename_pval,hours,contname,n,t)
    
        connectSQL;
        
        out = [];
        dat = [];
        
        for iii = 1:length(hours)       
            query = sprintf(['select fitness from %s ',...
                'where hours = %d and orf_name = ''%s'' ',...
                'and fitness is not null'],tablename_fit,hours(iii),contname);
            fitdat = fetch(conn, query);

            dat = [];
            for P = 0.01:0.01:0.05
                
                pn = fetch(conn, sprintf(['select count(*) from %s ',...
                    'where hours = %d and p <= %f and stat > 0'],...
                    tablename_pval,hours(iii),P));
                pN = fetch(conn, sprintf(['select count(*) from %s ',...
                    'where hours = %d and stat > 0'],...
                    tablename_pval,hours(iii)));
                
                nn = fetch(conn, sprintf(['select count(*) from %s ',...
                    'where hours = %d and p <= %f and stat < 0'],...
                    tablename_pval,hours(iii),P));
                nN = fetch(conn, sprintf(['select count(*) from %s ',...
                    'where hours = %d and stat < 0'],...
                    tablename_pval,hours(iii)));                
                
                p_cnt = 0;
                n_cnt = 0;
%                 t = 5000;
                
                for i = 1:t
                    [temp, ~] = datasample(fitdat.fitness, n);
                    [p, ~, stat] = ranksum(temp, fitdat.fitness, 'alpha', 0.05, 'tail', 'both', 'method', 'approximate');
                    if p <= P
                        if stat.zval > 0
                            p_cnt = p_cnt + 1;
                        else
                            n_cnt = n_cnt + 1;
                        end
                    end
                end
                
                dat = [dat; [P (pN.count___*p_cnt/t)/pn.count___ (nN.count___*n_cnt/t)/nn.count___]];
            end
            
            out = [out; [ones(length(dat),1)*hours(iii) dat]];
        end
        conn(close);
    end
    
    