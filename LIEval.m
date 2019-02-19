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

    expt_name = '4C2_R1';
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
    
    hours = fetch(conn, sprintf(['select distinct hours from %s ',...
            'order by hours asc'], tablename_jpeg));
    hours = hours.hours;
    
%%  PLATEWISE RMSE

    for i = 1:length(hours)
        for iii = 1:length(n_plates.x6144plate_1)
            clear rmse
            bg = fetch(conn, sprintf(['select a.* ',...
                'from %s a, %s b ',...
                'where a.hours = %d ',...
                'and a.pos = b.pos ',...
                'and b.%s = %d ',...
                'order by b.%s, b.%s'],...
                tablename_fit,p2c_info(1,:),hours(i),p2c_info(2,:),...
                iii,p2c_info(3,:),p2c_info(4,:)));
            for ii = 1:length(bg.average)
                rmse(ii,iii) = sqrt(mean(((bg.average(ii) - bg.bg(ii)).^2)));
            end

            max_avg = max(bg.average);
            min_avg = min(bg.average);

%             fig = figure('Renderer', 'painters', 'Position', [10 10 1920 1200],'visible','off');
            figure()
            subplot(2,2,1)
            heatmap(col2grid(bg.average),'ColorLimits',[min_avg max_avg]);
%             title(sprintf('Observed Pixel Count\n(Plate %d, %d hr)',iii,hours(i)))
            title('Observed Pixel Count')
            subplot(2,2,2)
            heatmap(col2grid(bg.bg),'ColorLimits',[min_avg max_avg]);
%             title(sprintf('Predicted Pixel Count\n(Plate %d, %d hr)',iii,hours(i)))
            title('Predicted Pixel Count')
            subplot(2,2,3)
            heatmap(col2grid(bg.fitness),'ColorLimits',[0.7 1.4]);
            title('Fitness')
            subplot(2,2,4)
            heatmap(col2grid(rmse(:,iii)),'ColorLimits',[0 120]);
            title(sprintf('RMSE (%0.3f)',mean(nanmean(rmse))))
            colormap parula
%             saveas(fig,sprintf('overview%d_%d.png',iii,hours(i)))
        end
    end

%%  POWER, FALSE POSITIVE AND ES

    for ii=1:length(hours)
        if conn.isopen == 0
            connectSQL;
        end
        cont_data = fetch(conn, sprintf(['select * from %s ',...
            'where orf_name = ''%s'' ',...
            'and fitness is not NULL and hours = %d'],...
            tablename_fit,cont.name,hours(ii)));

        rest_data = fetch(conn, sprintf(['select * from %s ',...
            'where orf_name != ''%s'' ',...
            'and fitness is not NULL and hours = %d'],...
            tablename_fit,cont.name,hours(ii)));

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

        temp_p = [];
        temp_s = [];
        for i = 1:length(rest_means)
            if sum(m<rest_means(i)) < tt/2
                if m<rest_means(i) == 0
                    temp_p = [temp_p; 1/tt];
                    temp_s = [temp_s; (rest_means(i) - contmean)/contstd];
                else
                    temp_p = [temp_p; ((sum(m<=rest_means(i)))/tt)*2];
                    temp_s = [temp_s; (rest_means(i) - contmean)/contstd];
                end
            else
                temp_p = [temp_p; ((sum(m>=rest_means(i)))/tt)*2];
                temp_s = [temp_s; (rest_means(i) - contmean)/contstd];
            end
        end

        pvals{ii} = temp_p; stat{ii} = temp_s;
        
        s = (((length(cont_data.fitness)*(std(cont_data.fitness))^2 +...
            length(rest_data.fitness)*(std(rest_data.fitness))^2)/...
            (length(cont_data.fitness) +...
            length(rest_data.fitness) - 2))^(0.5));

        ef_size = abs(mean(cont_data.fitness) - mean(rest_data.fitness))/s;
        N = 2*(1.96 * s/ef_size)^2;

        pow = (sum(temp_p<0.05)/length(rest_means))*100;
        (sum(temp_p>0.05)/length(rest_means))*100;
    %         median(ef_size)

%         fig = figure('Renderer', 'painters', 'Position', [10 10 480 300],'visible','off');
%         [f,xi] = ksdensity(cont_means);
%         plot(xi,f,'LineWidth',3)
%         hold on
%         [f,xi] = ksdensity(rest_means);
%         plot(xi,f,'LineWidth',3)
%         legend('control','rest of plate')
%         title(sprintf(['ES = %0.3f \n ',...
%             'Power = %0.3f'],ef_size,pow))
%         xlabel('Fitness')
%         ylabel('Density')
%         grid on
%         hold off
%         saveas(fig,sprintf('powes_%d.png',hours(ii)))

    fprintf('time %d hrs done\n', hours(ii))
    end
    
%%  NULL DISTRIBUTION
%   The fitness distribution of the positions used to create the LI model
    
    m = cont_data.fitness;
    tt = length(m);

    contp = [];
    for i = 1:10000
        temp = mean(datasample(cont_data.fitness, 1, 'Replace', false));
        if sum(m<temp) < tt/2
            if m<temp == 0
                contp = [contp; 1/tt];
            else
                contp = [contp; ((sum(m<=temp))/tt)*2];
            end
        else
            contp = [contp; ((sum(m>=temp))/tt)*2];
        end
    end
    contp(contp>1) = 1;
    
    figure()
    histogram(contp, 'Normalization', 'pdf')
    grid on
    xlabel('P Values')
    ylabel('Probability Density')
    title('NULL DISTRIBUTION')

%%  DATA UNDER PVAL CUT-OFFS
    
    p = 0:0.01:1;
    
    for ii = 1:length(hours)-2
        len = length(pvals{ii});
        fpdat = [];

        for i = 1:length(p)
            fp = sum(pvals{ii} <= p(i));
            fpdat = [fpdat; [p(i), fp/len]];
        end

    %     figure()
    %     plot(fpdat(:,1), fpdat(:,2))  
    %     grid on
    %     xlabel('p-value')
    %     ylabel('false positive rate')
    %     title('LI FPR in Expt')
    %     xlim([0,0.1])
    %     ylim([0,0.1])

        fig = figure('Renderer', 'painters', 'Position', [10 10 480 300],'visible','off');
        histogram(pvals{ii}, 'Normalization', 'cdf')
        hold on
        plot(0:0.01:1,0:0.01:1,'--r','LineWidth',3)
        grid on
        xlabel('P Value Cut-offs')
        ylabel('Proportion of Colonies')
        title(sprintf('Time = %d hrs',hours(ii)))
        xlim([0,1])
        ylim([0,1])
        saveas(fig,sprintf('pval_colonies_%d.png',hours(ii)))
    end
    
%     figure()
%     cdfplot(rest_data.average)
    
%%  SCHEME EFFECT

    schemedat = fetch(conn, ['select a.fitness, b.fitness ',...
        'from 4C2_6144_FITNESS a, 4C3_6144_FITNESS b ',...
        'where a.pos = b.pos and a.fitness is not NULL']);
    
    data005 = sum(abs(schemedat.fitness - schemedat.fitness_1) < 0.05)/...
        length(schemedat.fitness);
    
    figure()
    histogram(abs(schemedat.fitness - schemedat.fitness_1),...
        'Normalization','pdf')
    grid on
    xlabel('Fitness Difference')
    ylabel('Density')
    text(0.05,90,sprintf('<0.05 contains %0.2f%% of data',data005*100))
    hold on
    line(ones(121)*0.05,0:120)
    title('Upscale Scheme 1 v/s 2')
    
%%  POWER vs ES

    es_pow = [4.397 0.120; 4.898 0.152; 58.628 0.474; 99.012 1.230; 100 2.152];
    
    figure()
    scatter(es_pow(:,2), es_pow(:,1),'MarkerEdgeColor',[0 .5 .5],...
              'MarkerFaceColor',[0 .7 .7],...
              'LineWidth',1.5);
    grid on
    grid minor
    xlim([0,2.5])
    ylim([0,110])
    xlabel('Effect Size')
    ylabel('Power')
    title('Power V/S ES')
%     hold on
%     fit = polyfit(es_pow(:,2), es_pow(:,1),2); 
%     plot(0:0.01:2.5, polyval(fit,0:0.01:2.5))
%     hold off
    
    
%%  MIN REFERENCE
%   On rest of the plate
    
%     N = 2*(1.96 * s/ef_size)^2
% 
%     minref_p = [];
%     
%     for ii = 1:10
%         samp_dist =[];
%         samp_means = [];
%         for i=1:10
%             samp_dist(i,:) = datasample(rest_data.fitness, 8, 'Replace', false);
%             samp_means(i,:) = mean(samp_dist(i,:));
%     %             samp_std(i,:) = std(samp_dist(i,:));
%         end
%     %     ksdensity(samp_means);
% 
%         sampmean = nanmean(samp_means);
%         sampstd = nanstd(samp_means);
% 
%         m = cont_means;
%         tt = length(m);
% 
%         pvals = [];
%         stat = [];
%         for i = 1:length(samp_means)
%             if sum(m<samp_means(i)) < tt/2
%                 if m<samp_means(i) == 0
%                     pvals = [pvals; 1/tt];
%                     stat = [stat; (samp_means(i) - contmean)/contstd];
%                 else
%                     pvals = [pvals; ((sum(m<=samp_means(i))+1)/tt)*2];
%                     stat = [stat; (samp_means(i) - contmean)/contstd];
%                 end
%             else
%                 pvals = [pvals; ((sum(m>=samp_means(i))+1)/tt)*2];
%                 stat = [stat; (samp_means(i) - contmean)/contstd];
%             end
%         end
% 
%     %     s = (((length(cont_data.fitness)*(std(cont_data.fitness))^2 +...
%     %         length(samp_data.fitness)*(std(samp_data.fitness))^2)/...
%     %         (length(cont_data.fitness) +...
%     %         length(samp_data.fitness) - 2))^(0.5));
%     %     
%     %     ef_size = abs(mean(cont_data.fitness) - mean(samp_data.fitness))/s
% 
%         minref_p(ii) = (sum(pvals<0.05)/length(samp_means))*100;
%     end
%   
%     mean(minref_p)
%  

%%  MISSING DATA WHEN CALCULATING BG

%   Random data missing all over the plate

    miss_data = fetch(conn, sprintf(['select * from %s a, %s b ',...
        'where a.pos = b.pos and orf_name = ''%s'' ',...
        'order by %s, %s, %s'], tablename_fit, p2c_info(1,:),...
        cont.name,...
        p2c_info(2,:), p2c_info(3,:), p2c_info(4,:)));
    
    pos = datasample(cont_data.pos(1:length(cont_data.pos)/2),320)';
    pos = [pos, pos + 6144];

    a = contBG(miss_data.average(1:1536).*~ismember(miss_data.pos(1:1536), pos));
    b = col2grid(miss_data.average(1:1536))./a;
    c = contBG(miss_data.average(1537:1536*2).*~ismember(miss_data.pos(1537:1536*2), pos));
    d = col2grid(miss_data.average(1537:1536*2))./c;

    e = [grid2row(b), grid2row(d)];
    e = e(~isnan(e));

    m = e;
    tt = length(e);
    contp = [];

    for ii = 1:10000
        temp = mean(datasample(e, 1, 'Replace', false));
        if sum(m<temp) < tt/2
            if m<temp == 0
                contp = [contp; 1/tt];
            else
                contp = [contp; ((sum(m<=temp))/tt)*2];
            end
        else
            contp = [contp; ((sum(m>=temp))/tt)*2];
        end
    end
    
    figure()
    histogram(contp, 'Normalization', 'pdf')
    grid on
    xlabel('P Values')
    ylabel('Probability Density')
    title('NULL DISTRIBUTION')

%   Smudge type of missing

%%  VIRTUAL PLATE POWER ANALYSIS

    
    cont_hrs = 15;
    rest_hrs = 11;
    
    plate_fit = [];

    for iii = 1:length(n_plates.x6144plate_1)
        pos.all = fetch(conn, sprintf(['select a.pos ',...
            'from %s a ',...
            'where %s = %d ',...
            'order by %s, %s'],...
            p2c_info(1,:),...
            p2c_info(2,:),...
            n_plates.x6144plate_1(iii),...
            p2c_info(3,:),...
            p2c_info(4,:)));

        pos.cont = fetch(conn, sprintf(['select a.pos ',...
            'from %s a, %s b ',...
            'where a.pos = b.pos and %s = %d and a.orf_name = ''%s'' ',...
            'order by %s, %s'],...
            tablename_p2o,...
            p2c_info(1,:),...
            p2c_info(2,:),...
            n_plates.x6144plate_1(iii),...
            cont.name,...
            p2c_info(3,:),...
            p2c_info(4,:)));

        cont_pos = col2grid(ismember(pos.all.pos, pos.cont.pos));
        rest_pos = ~cont_pos;

        cont_data = fetch(conn, sprintf(['select a.* ',...
            'from %s a, %s b ',...
            'where a.hours = %d ',...
            'and a.pos = b.pos and b.%s = %d ',...
            'order by b.%s, b.%s'],...
            tablename_fit,p2c_info(1,:),cont_hrs,...
            p2c_info(2,:),1,p2c_info(3,:),p2c_info(4,:)));

        cont_avg = col2grid(cont_data.average).*cont_pos;
        plate_bg = col2grid(cont_data.bg);

        rest_data = fetch(conn, sprintf(['select a.* ',...
            'from %s a, %s b ',...
            'where a.hours = %d ',...
            'and a.pos = b.pos and b.%s = %d ',...
            'order by b.%s, b.%s'],...
            tablename_fit,p2c_info(1,:),rest_hrs,...
            p2c_info(2,:),1,p2c_info(3,:),p2c_info(4,:)));

        rest_avg = col2grid(rest_data.average).*rest_pos;
        plate_avg = cont_avg + rest_avg;

        plate_fit = plate_avg./plate_bg;
        
    end

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

    temp_p = [];
    temp_s = [];
    for i = 1:length(rest_means)
        if sum(m<rest_means(i)) < tt/2
            if m<rest_means(i) == 0
                temp_p = [temp_p; 1/tt];
                temp_s = [temp_s; (rest_means(i) - contmean)/contstd];
            else
                temp_p = [temp_p; ((sum(m<=rest_means(i)))/tt)*2];
                temp_s = [temp_s; (rest_means(i) - contmean)/contstd];
            end
        else
            temp_p = [temp_p; ((sum(m>=rest_means(i)))/tt)*2];
            temp_s = [temp_s; (rest_means(i) - contmean)/contstd];
        end
    end

    pvals{ii} = temp_p; stat{ii} = temp_s;

    s = (((length(cont_data.fitness)*(std(cont_data.fitness))^2 +...
        length(rest_data.fitness)*(std(rest_data.fitness))^2)/...
        (length(cont_data.fitness) +...
        length(rest_data.fitness) - 2))^(0.5));

    ef_size = abs(mean(cont_data.fitness) - mean(rest_data.fitness))/s;
    N = 2*(1.96 * s/ef_size)^2;

    pow = (sum(temp_p<0.05)/length(rest_means))*100;
    (sum(temp_p>0.05)/length(rest_means))*100;
%         median(ef_size)

%         fig = figure('Renderer', 'painters', 'Position', [10 10 480 300],'visible','off');
%         [f,xi] = ksdensity(cont_means);
%         plot(xi,f,'LineWidth',3)
%         hold on
%         [f,xi] = ksdensity(rest_means);
%         plot(xi,f,'LineWidth',3)
%         legend('control','rest of plate')
%         title(sprintf(['ES = %0.3f \n ',...
%             'Power = %0.3f'],ef_size,pow))
%         xlabel('Fitness')
%         ylabel('Density')
%         grid on
%         hold off
%         saveas(fig,sprintf('powes_%d.png',hours(ii)))