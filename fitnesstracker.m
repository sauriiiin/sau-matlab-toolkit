%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  fitnesstracker.m

%   Author: Saurin Parikh, April 2018
%   dr.saurin.parikh@gmail.com

%   Tracking and plotting fitness of orfs through different stages of the
%   pilot experiment.

%%  INITIALIZE

    col_analyzer_path = '/users/saurinparikh/documents/matlab/matlab-colony-analyzer-toolkit-master';
    bean_toolkit_path = '/users/saurinparikh/documents/matlab/bean-matlab-toolkit-master';
    sau_toolkit_path = '/users/saurinparikh/documents/matlab/sau-matlab-toolkit';
    addpath(genpath(col_analyzer_path));
    addpath(genpath(bean_toolkit_path));
    addpath(genpath(sau_toolkit_path));
%     javaaddpath(uigetfile());
    
%   Connection details
    connectSQL;
    
%%  DATA
    
%     orfs = fetch(conn, ['select orf_name from PT_SA_CN_6144_RES_eFDR ',....
%         'where hours = 12 and effect_cs = 1 order by cs_median desc']);

    orfs = fetch(conn, ['select orf_name from PT_SA_CN_6144_RES_eFDR ',....
        'where hours = 6 and effect_cs = 1 order by cs_median desc']);
    
    orfs.orf_name{length(orfs.orf_name)+1} = 'BF_control';
    
    tables = {...
%         {'PT_PS2A_CN_1536', 29};...
%         {'PT_PS2B_CN_1536', 29};...
        {'PT_SB_CN_1536', 4,8,16,24,32};...
%         {'PT_SA_CN_6144', 6,9,12,14}...
        };
    
    clear data
    
    for i=1:length(orfs.orf_name)
        for ii=1:length(tables)
            for iii=2:length(tables{ii})
                temp = fetch(conn, sprintf(['select cs_median from %s ',...
                    'where hours = %d and orf_name = ''%s'' '],...
                    [tables{ii}{1},'_FITNESS_STATS'],...
                    tables{ii}{iii}, orfs.orf_name{i}));
                data{i}{ii}{iii-1} = temp.cs_median;
            end
        end
    end
        
%%  PLOT
    
    plotdat = [1:5];
    temp = [];
    for i=1:length(orfs.orf_name)
        for ii=1:length(data{i})
            for iii=1:length(data{i}{ii})
                temp = [temp, data{i}{ii}{iii}];
            end
        end
        plotdat = [plotdat;temp];
        temp = [];
    end
    
    figure('rend','painters','pos',[20 20 1000 1000])
    hold on
    for i=2:80
        plot(plotdat(1,:),plotdat(i,:))
        hold on
    end
    plot(plotdat(1,:),plotdat(81,:),'-b','LineWidth',3)
%     legend(orfs.orf_name)
    hold off
        
%%  GROWTH DATA
    
%   distinct strain_ids
    query = ['select strain_id from BARFLEX_SPACE_AGAR ',...
        'where orf_name in ',...
        '(select orf_name ',...
        'from PT_SA_CN_6144_RES_eFDR ',...
        'where hours = 6 ',...
        'and effect_cs = 1)'];
    strains = fetch(conn, query);

%   distinct hours

    query = ['select distinct hours from PT_SA_CN_6144_SPATIAL ',...
        'order by hours asc '];
    hours = fetch(conn, query);
    
%   average csMs for all strain_ids at different hours
    
    for i = 1:length(strains.strain_id)   
        query = sprintf(['select b.strain_id, a.hours, AVG(a.csM) avgs ',...
            'from PT_SA_CN_6144_SPATIAL a, PT_pos2strainid b ',...
            'where a.pos = b.pos and b.strain_id = %0.f and a.average != 0 ',...
            'group by a.hours, b.strain_id ',...
            'order by b.strain_id, a.hours'], strains.strain_id(i));
        avgs{i} = fetch(conn, query);
    end
    
%%  AVERAGE PIXEL GROWTH PLOTS

    for ii=2:length(strains.strain_id)
        if ~isempty(avgs{ii})
            x = hours.hours;
            figure('rend','painters','pos',[10 10 600 500])
            xlim([hours.hours(1),hours.hours(end)])
            hold on
            plot(x,avgs{1}.avgs - avgs{1}.avgs(1),'r--o',...
                x,avgs{ii}.avgs - avgs{ii}.avgs(1),'b--o','LineWidth',3)
            xlabel('Hours')
            ylabel('Average Pixels')
            title('Colony Size Comparison')
            legend('control',num2str(avgs{ii}.strain_id(1)),'Location','northwest')
            hold off
        end
    end
    
%%  Colony Size Increment Plots
    
    for ii=1:length(strains.strain_id)    
        for i=2:length(hours.hours)
            inc{ii}(i-1) = (avgs{ii}.avgs(i)-avgs{ii}.avgs(i-1))/...
                avgs{ii}.avgs(i-1)*100;
        end      
    end

    for ii=2:length(strains.strain_id)
        x = hours.hours(2:end);
%         figure()
        figure('rend','painters','pos',[10 10 600 500])
%         ylim([0,380])
        xlim([hours.hours(2),hours.hours(end)])
        hold on
        plot(x,inc{1},'r--o',x,inc{ii},'b--o','LineWidth',2)
        %xticks(hours(1):hours(end))
        %xticklabels(xlabels)
        xlabel('Hours')
        ylabel('Growth Percent (%)')
        title('Colony Size Increment (csM)')
        legend('control',num2str(avgs{ii}.strain_id(1)),'Location','northwest')
        hold off
    end
    
%%  Colony Size wrt Control over time

    for ii=2:length(strains.strain_id)
        x = hours.hours;
        figure()
        ylim([0.3,1.1])
        xlim([hours.hours(1),hours.hours(end)])
        hold on
        plot(x,avgs{ii}.avgs./avgs{1}.avgs,'r--o','LineWidth',2)
        %xticks(hours(1):hours(end))
        %xticklabels(xlabels)
        xlabel('Hours')
        ylabel('CS Ratio (Strain/Control)')
        title('Colony Size Comparison (csM)')
        legend(num2str(avgs{ii}.strain_id(1)),'Location','northwest')
        hold off
    end

%     for ii=2:length(strains.strain_id)
%         x = hours.hours;
%         figure()
% %         ylim([0,1.1])
%         xlim([hours.hours(1),hours.hours(end)])
%         hold on
%         plot(x,(avgs{ii}.avgs-avgs{1}.avgs)./avgs{1}.avgs,'r--o','LineWidth',2)
%         %xticks(hours(1):hours(end))
%         %xticklabels(xlabels)
%         xlabel('Hours')
%         ylabel('CS Ratio (Strain-Control/Control)')
%         title('Colony Size Comparison (csM)')
%         legend(num2str(avgs{ii}.strain_id(1)),'Location','northwest')
%         hold off
%     end   

    x = hours.hours;
    sid = [1];
    figure('rend','painters','pos',[10 10 1200 1000])
%     figure()
%     ylim([0.6,1.2])
    xlim([hours.hours(1),hours.hours(end)])
    plot(x,ones(7,1),'r--','LineWidth',.5)
    hold on       
    for ii=2:length(strains.strain_id)     
        plot(x,avgs{ii}.avgs./avgs{1}.avgs,'LineWidth',3)
        sid = [sid; avgs{ii}.strain_id(1)];
    end
    xlabel('Hours')
    ylabel('CS Ratio (Strain/Control)')
    legend(num2str(sid),'Location','southeast')
    title('Colony Size Comparison (csM)')
    hold off
    
%%
    conn(close);
        