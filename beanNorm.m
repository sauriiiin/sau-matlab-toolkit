%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  beanNorm.m

%   Author: Saurin Parikh, June 2019
%   dr.saurin.parikh@gmail.com

%%

    function data_fit = beanNorm(hours,density,n_plates,p2c_info,tablename,sql_info)
    
        if isempty(sql_info)
            connectSQL;
        else
            conn = connSQL(sql_info);
        end
        
        for ii = 1:length(hours)
            temp = [];
            for iii = 1:length(n_plates.plate)

                pos.all = fetch(conn, sprintf(['select a.pos ',...
                    'from %s a ',...
                    'where %s = %d ',...
                    'and density = %d ',...
                    'order by %s, %s'],...
                    p2c_info(1,:),...
                    p2c_info(2,:),...
                    n_plates.plate(iii),...
                    density,...
                    p2c_info(3,:),...
                    p2c_info(4,:)));

                avg_data = fetch(conn, sprintf(['select a.pos, a.hours, a.average ',...
                    'from %s a, %s b ',...
                    'where a.pos = b.pos and hours = %d and %s = %d ',...
                    'order by %s, %s'],...
                    tablename,...
                    p2c_info(1,:),...
                    hours(ii),...
                    p2c_info(2,:),...
                    n_plates.plate(iii),...
                    p2c_info(3,:),...
                    p2c_info(4,:)));

        %%  CALCULATE BACKGROUND
                 bg{iii} = apply_correction( ...
                    grid2row(avg_data.average), 'dim', 2, ...
                    InterleaveFilter(SpatialBorderMedian('SpatialFilter', ...
                    SpatialMedian('windowSize', 9))),...
                    PlateMode() )';
                
                bg{iii}(bg{iii} == 0) = NaN;
                temp = abs([temp; [pos.all.pos, ones(length(pos.all.pos),1)*hours(ii),...
                    avg_data.average./bg{iii}, avg_data.average, bg{iii}]]);
            end
            data_fit{ii} = temp;
        end
    end
    
%%  END    
    
