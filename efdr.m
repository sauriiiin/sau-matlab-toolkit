%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  efdr.m

%   Author: Saurin Parikh, August 2018
%   dr.saurin.parikh@gmail.com
%
%   Overall eFDR rather than BeFDR and DeFDR that empfdr function generates
    

%%
    function out = efdr(tablename_fit,tablename_pval,hours,contname,t)
    
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
                
                n = fetch(conn, sprintf(['select count(*) from %s ',...
                    'where hours = %d and p <= %f'],...
                    tablename_pval,hours(iii),P));
                N = fetch(conn, sprintf(['select count(*) from %s ',...
                    'where hours = %d'],...
                    tablename_pval,hours(iii)));               
                
                cnt = 0;
                for i = 1:N.count___
                    [temp, ~] = datasample(fitdat.fitness, t);
                    [p, ~, ~] = ranksum(temp, fitdat.fitness, 'alpha', 0.05, 'tail', 'both', 'method', 'approximate');
                    if p <= P
                        cnt = cnt + 1;
                    end
                end
                
                dat = [dat; [P cnt/n.count___ ]];
            end
            
            out = [out; [ones(length(dat),1)*hours(iii) dat]];
        end      
        conn(close);    
    end
    
    