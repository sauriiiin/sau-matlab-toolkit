%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  LIEval.m

%   Author: Saurin Parikh, February 2019
%   dr.saurin.parikh@gmail.com

%   Evaluation of the LI based control normalization

%%  Load Paths to Files and Data

    col_analyzer_path = '/Users/saur1n/Documents/GitHub/Matlab-Colony-Analyzer-Toolkit';
    bean_toolkit_path = '/Users/saur1n/Documents/GitHub/bean-matlab-toolkit';
    sau_toolkit_path = '/Users/saur1n/Documents/GitHub/sau-matlab-toolkit';
    addpath(genpath(col_analyzer_path));
    addpath(genpath(bean_toolkit_path));
    addpath(genpath(sau_toolkit_path));
%     javaaddpath(uigetfile());

%%  Add MCA toolkit to Path
    add_mca_toolkit_to_path

%%  Initialization

%     Set preferences with setdbprefs.
    setdbprefs('DataReturnFormat', 'structure');
    setdbprefs({'NullStringRead';'NullStringWrite';'NullNumberRead';'NullNumberWrite'},...
                  {'null';'null';'NaN';'NaN'})

    expt_name = '4C';
    density = 6144;
    
%   MySQL Table Details  
    
    tablename_jpeg      = sprintf('%s_%d_JPEG',expt_name,density);
    tablename_norm      = sprintf('%s_%d_NORM',expt_name,density);
    tablename_fit       = sprintf('%s_%d_FITNESS',expt_name,density);
    tablename_fits      = sprintf('%s_%d_FITNESS_STATS',expt_name,density);
    tablename_es        = sprintf('%s_%d_FITNESS_ES',expt_name,density);
    tablename_pval      = sprintf('%s_%d_PVALUE',expt_name,density);
    tablename_res       = sprintf('%s_%d_RES',expt_name,density);
    
    tablename_p2o       = 'VP_pos2orf_name1';
    tablename_bpos      = 'VP_borderpos';
    
%   Reference Strain Name

    cont.name           = 'BF_control';
    
%   MySQL Connection and fetch initial data

    connectSQL;
    
    p2c_info(1,:) = 'VP_pos2coor6144';
    p2c_info(2,:) = '6144plate      ';
    p2c_info(3,:) = '6144col        ';
    p2c_info(4,:) = '6144row        ';

    p2c = fetch(conn, sprintf(['select * from %s a ',...
        'order by a.%s, a.%s, a.%s'],...
        p2c_info(1,:),...
        p2c_info(2,:),...
        p2c_info(3,:),...
        p2c_info(4,:)));
    
    n_plates = fetch(conn, sprintf(['select distinct %s from %s a ',...
        'order by %s asc'],...
        p2c_info(2,:),...
        p2c_info(1,:),...
        p2c_info(2,:)));
    
%%  PLATEWISE RMSE

    for iii = 1:length(n_plates.x6144plate_1)
        bg = fetch(conn, sprintf(['select a.* ',...
            'from %s a, %s b ',...
            'where a.pos = b.pos ',...
            'and b.%s = %d ',...
            'order by b.%s, b.%s'],...
            tablename_fit,p2c_info(1,:),p2c_info(2,:),...
            iii,p2c_info(3,:),p2c_info(4,:)));
        for ii = 1:length(bg.average)
            rmse(ii,iii) = sqrt(mean(((bg.average(ii) - bg.bg(ii)).^2)));
        end

        max_avg = max(bg.average);
        min_avg = min(bg.average);

        figure()
        subplot(2,2,1)
        heatmap(col2grid(bg.average),'ColorLimits',[min_avg max_avg])
        title('Observed Pixel Count')
        subplot(2,2,2)
        heatmap(col2grid(bg.bg),'ColorLimits',[min_avg max_avg])
        title('Predicted Pixel Count')
        subplot(2,2,3)
        heatmap(col2grid(bg.fitness),'ColorLimits',[0.7 1.4])
        title('Fitness')
        subplot(2,2,4)
        heatmap(col2grid(rmse(:,iii)),'ColorLimits',[0 120])
        title('RMSE')
        colormap parula
    end

%%  POWER, FALSE POSITIVE AND ES

%         connectSQL;
    cont_data = fetch(conn, sprintf(['select * from %s ',...
        'where orf_name = ''%s'' ',...
        'and fitness is not NULL'],tablename_fit,cont.name));

    rest_data = fetch(conn, sprintf(['select * from %s ',...
        'where orf_name != ''%s'' ',...
        'and fitness is not NULL'],tablename_fit,cont.name));

    cont_dist = [];
    cont_means = [];
    for i=1:100000
        cont_dist(i,:) = datasample(cont_data.fitness, 8, 'Replace', false);
        cont_means(i,:) = mean(cont_dist(i,:));
    end
%     ksdensity(cont_means);

    rest_dist =[];
    rest_means = [];
    for i=1:100000
        rest_dist(i,:) = datasample(rest_data.fitness, 8, 'Replace', false);
        rest_means(i,:) = mean(rest_dist(i,:));
%             rest_std(i,:) = std(rest_dist(i,:));
    end
%     ksdensity(rest_means);

    contmean = nanmean(cont_means);
    contstd = nanstd(cont_means);
    restmean = nanmean(rest_means);
    reststd = nanstd(rest_means);

    m = cont_means;
    tt = length(m);

    pvals = [];
    stat = [];
    for i = 1:length(rest_means)
        if sum(m<rest_means(i)) < tt/2
            if m<rest_means(i) == 0
                pvals = [pvals; 1/tt];
                stat = [stat; (rest_means(i) - contmean)/contstd];
            else
                pvals = [pvals; ((sum(m<=rest_means(i))+1)/tt)*2];
                stat = [stat; (rest_means(i) - contmean)/contstd];
            end
        else
            pvals = [pvals; ((sum(m>=rest_means(i))+1)/tt)*2];
            stat = [stat; (rest_means(i) - contmean)/contstd];
        end
    end

    ef_size = abs(mean(cont_data.fitness) - mean(rest_data.fitness))/...
        (((length(cont_data.fitness)*(std(cont_data.fitness))^2 +...
        length(rest_data.fitness)*(std(rest_data.fitness))^2)/...
        (length(cont_data.fitness) +...
        length(rest_data.fitness) - 2))^(0.5))

    pow = (sum(pvals<0.05)/length(rest_means))*100
    (sum(pvals>0.05)/length(rest_means))*100
%         median(ef_size)

    figure()
    [f,xi] = ksdensity(cont_means);
    plot(xi,f,'LineWidth',3)
    hold on
    [f,xi] = ksdensity(rest_means);
    plot(xi,f,'LineWidth',3)
    legend('control','rest of plate')
    title(sprintf(['ES = %0.3f \n ',...
        'Power = %0.3f'],ef_size,pow))
    xlabel('Fitness')
    ylabel('Density')
    grid on
    hold off

