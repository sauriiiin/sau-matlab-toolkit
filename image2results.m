%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  image2results.m

%   Author: Saurin Parikh, September 2018
%   dr.saurin.parikh@gmail.com
%   
%   Analyze Images -> Upload Data
%   and then
%   JPEG data to Q-VALUES for any experiment with Control Normalization.
%   Inputs Required:
%       sql info (username, password, database name), experiment name,
%       pos2coor tablename, pos2orf_name tablename, control name
% 
%   Recursive parent directory search to search all subdirectories
%   containing images.

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
    
%     prompt={'Enter the name of your MySQL Username:'};
%     username = char(inputdlg(prompt,...
%         'SQL Username',1,...
%         {'user'}));
    
%     prompt={'Enter the name of your MySQL Password:'};
%     pwd = char(inputdlg(prompt,...
%         'SQL Password',1,...
%         'password'));

%     prompt={'Enter the name of your MySQL Database:'};
%     db = char(inputdlg(prompt,...
%         'SQL Database Name',1,...
%         {'database'}));

    prompt={'Enter a name for your experiment:'};
    name='expt_name';
    numlines=1;
    defaultanswer={'test'};
    expt_name = char(inputdlg(prompt,name,numlines,defaultanswer));
  
%   Set Precision
%     digits(6);
    
%   Collect all subfolders and files within them from a folder
% 
    hours = []; 
    files = {};
    filedir = dir(uigetdir());
    dirFlags = [filedir.isdir] & ~strcmp({filedir.name},'.') & ~strcmp({filedir.name},'..');
    subFolders = filedir(dirFlags);
    for k = 1 : length(subFolders)
        tmpdir = strcat(subFolders(k).folder, '/',  subFolders(k).name);
        files = [files; dirfiles(tmpdir, '*.JPG')];  
        hrs = strfind(tmpdir, '/'); hrs = tmpdir(hrs(end)+1:end);
        hours = [hours, str2num(hrs(1:end-1))];
    end
    
    if isempty(hours)
        hours = -1;
    end
      
    switch questdlg('Is density 384 or higher?',...
        'Density Options',...
        'Yes','No','Yes')
        case 'Yes'
            density = str2num(questdlg('What density plates are you using?',...
                'Density Options',...
                '384','1536','6144','6144'));
            if density == 6144
                dimensions = [64 96];
            elseif density == 1536
                dimensions = [32 48];
            else
                dimensions = [16 24];
            end
        case 'No'
            density = 96;
            dimensions = [8 12];
    end
    
    if density == 96
        poslim = [0,1000];
    elseif density == 384
        poslim = [1000,10000];
    elseif density == 1536
        poslim = [10000,100000];
    else %density == 6144
        poslim = [100000,1000000];
    end
    
%   MySQL Table Details  
    
    tablename_jpeg      = sprintf('%s_%d_JPEG',expt_name,density); 
    tablename_raw       = sprintf('%s_%d_RAW',expt_name,density); 
    tablename_spa       = sprintf('%s_%d_SPATIAL',expt_name, density);
    tablename_fit       = sprintf('%s_%d_FITNESS',expt_name,density);
    tablename_fits      = sprintf('%s_%d_FITNESS_STATS',expt_name,density);
    tablename_es        = sprintf('%s_%d_FITNESS_ES',expt_name,density);
    tablename_pval      = sprintf('%s_%d_PVALUE',expt_name,density);
    tablename_pval2     = sprintf('%s_%d_PVALUE2',expt_name,density);
    tablename_qval      = sprintf('%s_%d_QVALUE',expt_name,density);
    tablename_perc      = sprintf('%s_%d_PERC',expt_name,density);
    tablename_efdr      = sprintf('%s_%d_eFDR',expt_name,density);
    tablename_efdr2     = sprintf('%s_%d_eFDR2',expt_name,density);
    tablename_res       = sprintf('%s_%d_RES',expt_name,density);
    tablename_res_es    = sprintf('%s_%d_RES_ES',expt_name,density);
    tablename_res_efdr  = sprintf('%s_%d_RES_eFDR',expt_name,density);
    
%   MySQL Connection and fetch initial data

    connectSQL;
    
    prompt={'Enter the name of your P2C Table:',...
        'Name of the "Plate" column:',...
        'Name of the "Column" column:',...
        'Name of the "Row" column:'};
    name='P2C Table Info';
    defaultanswers={'expt_pos2coor','384plate','384col','384row'};
    p2c_info = char(inputdlg(prompt,...
        name,1,defaultanswers));

    p2c = fetch(conn, sprintf(['select * from %s a ',...
        'order by a.%s, a.%s, a.%s'],...
        p2c_info(1,:),...
        p2c_info(2,:),...
        p2c_info(3,:),...
        p2c_info(4,:)));
    
    prompt={'Enter the name of your pos2orf_name table:'};
    tablename_p2o = char(inputdlg(prompt,...
        'pos2orf_name Table Name',1,...
        {'expt_pos2orf_name'}));
    
    prompt={'Enter the number of replicates in this study:'};
    replicate = str2num(cell2mat(inputdlg(prompt,...
        'Replicates',1,...
        {'4'})));

%     if density >384
%         prompt={'Enter the name of your source table:'};
%         tablename_null = char(inputdlg(prompt,...
%             'Source Table',1,...
%             {'expt_384_SPATIAL'}));
%         source_nulls = fetch(conn, sprintf(['select a.pos from %s a ',...
%             'where a.csS is NULL ',...
%             'order by a.pos asc'],tablename_null));
%     end
    
    prompt={'Enter the control stain orf_name:'};
    cont.name = char(inputdlg(prompt,...
        'Control Strain',1,...
        {'BF_control'}));
    
    prompt={'Enter the Border Position Table Name:'};
    tablename_bpos = char(inputdlg(prompt,...
        'Border Positions',1,...
        {'expt_borderpos'}));
    
    prompt={'Enter the Smudge Box Table Name:'};
    tablename_sbox = char(inputdlg(prompt,...
        'Smudge Box',1,...
        {'expt_smudgebox'}));
    
%   Fetch Protogenes

    proto = fetch(conn, ['select orf_name from PROTOGENES ',...
        'where longer + selected + translated < 3']);
    
    close(conn);
    
%%  ANALYZE DATA
    
    if density <= 384
        image2spatial_LD(files, hours, dimensions,...
            p2c, tablename_raw, tablename_spa)
    else
%%  Load Analyzed Data

        cs = load_colony_sizes(files);
        size(cs)    % should be = (number of plates x 3 x number of time points) x density

%%  Mean the colony sizes from each of the images

        cs_mean = [];
        tmp = cs';

        for ii = 1:3:length(files)
            cs_mean = [cs_mean, mean(tmp(:,ii:ii+2),2)];
        end

        cs_mean = cs_mean';

%%  Putting Colony Size(pixels) and averages together

        master = [];
        tmp = [];
        i = 1;
        for ii = 1:3:size(cs,1)
            tmp = [cs(ii,:); cs(ii+1,:); cs(ii+2,:);...
                cs_mean(i,:)];
            master = [master, tmp];
            i = i + 1;
        end
        master = master';

%%  Upload JPEG Data to SQL

        connectSQL;

        exec(conn, sprintf('drop table %s',tablename_jpeg));  
        exec(conn, sprintf(['create table %s (pos int not null, hours int not null,'...
            'replicate1 int not null,'...
            'replicate2 int not null, replicate3 int not null, average double not null)'], tablename_jpeg));

        colnames_jpeg = {'pos','hours'...
            'replicate1','replicate2','replicate3',...
            'average'};

        tmpdata = [];
        for ii=1:length(hours)
            tmpdata = [tmpdata; [p2c.pos, ones(length(p2c.pos),1)*hours(ii)]];
        end

        data = [tmpdata,master];
        tic
        datainsert(conn,tablename_jpeg,colnames_jpeg,data);
        toc

%%  Upload RAW Data to SQL with Control Normalization

        hours = fetch(conn, sprintf(['select distinct hours from %s ',...
            'order by hours asc'], tablename_jpeg));
        hours = hours.hours;

        exec(conn, sprintf('drop table %s',tablename_raw));  
        exec(conn, sprintf(['create table %s (pos int not null, hours int not null,'...
            'replicate1 int not null,'...
            'replicate2 int not null, replicate3 int not null, average double not null,'...
            'csS double not null, csM double not null)'], tablename_raw));

        colnames_raw = {'pos','hours'...
            'replicate1','replicate2','replicate3',...
            'average','csS','csM'};

        avg_data = ControlNorm(density,hours,tablename_jpeg,tablename_p2o,p2c_info,cont.name);

        for ii = 1:length(avg_data)
            for iii = 1:length(avg_data{ii})
                if ~isempty(avg_data{ii}{iii})
                    avg_data{ii}{iii}.csS(isnan(avg_data{ii}{iii}.csS)) = 0;
                    avg_data{ii}{iii}.csM(isnan(avg_data{ii}{iii}.csM)) = 0;
                    datainsert(conn,tablename_raw,colnames_raw,avg_data{ii}{iii});
                end
            end
        end

%%  RAW to SPATIAL

        clear data

        exec(conn, sprintf('drop table %s',tablename_spa));
        exec(conn, sprintf(['create table %s (pos int not null, hours int not null,'...
            'replicate1 int not null,'...
            'replicate2 int not null, replicate3 int not null, average double null,'...
            'csS double null, csM double null)'],tablename_spa));

        colnames_spa = {'pos','hours',...
            'replicate1','replicate2','replicate3',...
            'average','csS','csM'};  

        for ii = 1:length(hours)     
            data{ii} = fetch(conn, sprintf(['select * from ',...
                '%s where hours = %d'],tablename_raw,hours(ii)));

%           Cleanning RAW DATA
%             n_plate = length(data{ii}.pos)/density;
%             rep_data = [data{ii}.replicate1, data{ii}.replicate2,...
%                 data{ii}.replicate3];
%             [cleaned_rep_data, data{ii}.average] = ...
%                     clean_raw_data(rep_data, n_plate, density, 20);
%             data{ii}.replicate1 = cleaned_rep_data(:,1);
%             data{ii}.replicate2 = cleaned_rep_data(:,2);
%             data{ii}.replicate3 = cleaned_rep_data(:,3); 

%           Avoiding light artefact
            pos_zeros = fetch(conn, sprintf(['select pos from ',...
                '%s where average < 10 and hours = %d'], tablename_raw, hours(ii)));
            if isempty(pos_zeros) ~= 1
                pos_zeros = pos_zeros.pos;
                [la, lb] = ismember(pos_zeros, data{ii}.pos);
                pos_zeros = lb(la);
                data{ii}.average(pos_zeros) = 99999;
                data{ii}.csS(pos_zeros) = 99999;
                data{ii}.csM(pos_zeros) = 99999;
            end

%           NULLs from BORDERS
            borders = fetch(conn, sprintf('select pos from %s',...
                tablename_bpos));
            borders = borders.pos;
            [la, lb] = ismember(borders, data{ii}.pos);
            borders = lb(la);
            data{ii}.average(borders) = 99999;
            data{ii}.csS(borders) = 99999;
            data{ii}.csM(borders) = 99999;

% %           NULLs from SMUDGE BOX
            smudge = fetch(conn, sprintf('select pos from %s',...
                tablename_sbox));
            smudge = smudge.pos;
            [la, lb] = ismember(smudge, data{ii}.pos);
            smudge = lb(la);
            data{ii}.average(smudge) = 99999;
            data{ii}.csS(smudge) = 99999;
            data{ii}.csM(smudge) = 99999;
% 
% %           NULLs from Source Plates
%             if density >384
%                 source_zeros = [];
%                 for i = 1:replicate
%                     [la, lb] = ismember(source_nulls.pos, data{ii}.pos - (poslim(1)*i));
%                     source_zeros = lb(la);
%                     data{ii}.average(source_zeros) = 99999;
%                     data{ii}.csS(source_zeros) = 99999;
%                     data{ii}.csM(source_zeros) = 99999;
%                 end
%             end

            tic
            datainsert(conn,tablename_spa,colnames_spa,data{ii}); 
            toc
        end

%%  SPATIAL to FITNESS

        orf_data = fetch(conn, sprintf(['select * from %s where pos between ',...
            '%d and %d ',...
            'order by pos asc'],tablename_p2o, poslim(1), poslim(2)));
        pos = orf_data.pos;
        orf_names = orf_data.orf_name;

        exec(conn, sprintf('drop table %s',tablename_fit));
        exec(conn, sprintf(['create table %s (orf_name varchar(255) null, ',...
            'pos int not null, hours int not null, average double null, ',...
            'fitness double null)'],tablename_fit));

        colnames_fit = {'orf_name','pos','hours',...
            'average','fitness'};

        for ii = 1:length(hours)
            spatial = fetch(conn, sprintf(['select pos, hours, average, csS from ',...
                '%s where hours = %d ',...
                'order by pos asc'],tablename_spa,hours(ii)));
            fit_data{ii}.orf_name = orf_names;
            fit_data{ii}.pos = num2cell(spatial.pos);
            fit_data{ii}.hours = num2cell(spatial.hours);
            fit_data{ii}.average = num2cell(spatial.average);
            fit_data{ii}.fitness = num2cell(spatial.csS);
            tic
            datainsert(conn,tablename_fit,colnames_fit,fit_data{ii});
            toc
        end

%%  Converting 99999s
%   to NULLs

        exec(conn, sprintf(['update %s '...
            'set average = NULL, csS = NULL, csM = NULL '...
            'where average = 99999 or csS = 99999 or csM = 99999'],tablename_spa));

        exec(conn, sprintf(['update %s '...
            'set average = NULL, fitness = NULL '...
            'where average = 99999 or fitness = 99999'],tablename_fit));

%%  FITNESS STATS

        clear data

        exec(conn, sprintf('drop table %s', tablename_fits));
        exec(conn, sprintf(['create table %s (orf_name varchar(255) null, ',...
            'hours int not null, N int not null, cs_mean double null, ',...
            'cs_median double null, cs_std double null)'],tablename_fits));

        colnames_fits = {'orf_name','hours','N','cs_mean','cs_median','cs_std'};

        stat_data = fit_stats(tablename_fit);
        tic
        datainsert(conn,tablename_fits,colnames_fits,stat_data)
        toc

%%  FITNESS to P-VALUES

        exec(conn, sprintf('drop table %s',tablename_pval));
        exec(conn, sprintf(['create table %s (orf_name varchar(255) null,'...
            'hours int not null, p double null, stat double null)'],tablename_pval));

        colnames_pval = {'orf_name','hours','p','stat'};

        for ii = 1:length(hours)
            all = fetch(conn, sprintf(['select orf_name, hours, fitness FROM ',...
                '%s where orf_name is not NULL ',...
                'and orf_name != "null" and hours = %d ',...
                'order by orf_name asc'], tablename_fit, hours(ii)));

            cont.posy   = find(strcmpi(all.orf_name, cont.name)==1);
            cont.yield  = all.fitness(cont.posy, 1);

            pdata{ii}       = fitp(cont, all);
            pdata{ii}.hours = ones(length(pdata{ii}.orf_name),1)*hours(ii);
            pdata{ii}       = orderfields(pdata{ii}, [1,4,2,3]);
            tic
            sqlwrite(conn,tablename_pval,struct2table(pdata{ii}));
            toc
        end

%%  FITNESS to Emperical P-VALUES
%     
%         exec(conn, sprintf('drop table %s',tablename_pval2));
%         exec(conn, sprintf(['create table %s (orf_name varchar(255) null,'...
%             'hours int not null, p double null, stat double null)'],tablename_pval2));
%         
%         colnames_pval2 = {'orf_name','hours','p','stat'};
%         
%         pdata = emp_p(tablename_fit,tablename_fits,hours,cont.name,16);
%         
%         tic
%         for ii = 1:length(hours)
%             datainsert(conn,tablename_pval2,colnames_pval2,pdata{ii});
%         end
%         toc

%%  P-VALUES to Q-VALUES

        exec(conn, sprintf('drop table %s',tablename_qval));
        exec(conn, sprintf(['create table %s (orf_name varchar(255) null, '...
            'hours int not null, q double null, fdr double null ,'...
            'p double null, stat double null)'],...
            tablename_qval));

        colnames_qval = {'orf_name','hours','q','fdr','p','stat'};

        for ii = 1:length(hours)
            allp = fetch(conn, sprintf(['select * FROM %s ',...
                'where hours = %d and orf_name is not NULL and orf_name != "null"'],...
                tablename_pval,hours(ii))); 
            qdata{ii}       = fitq2(allp);
            qdata{ii}.hours = allp.hours;
            qdata{ii}       = orderfields(qdata{ii}, [1,6,2,5,3,4]);
            tic
            sqlwrite(conn,tablename_qval,struct2table(qdata{ii}));
            toc
        end

%%  EFECT_SIZE CALCULATION

        exec(conn, sprintf('drop table %s', tablename_es));
        exec(conn, sprintf(['create table %s (orf_name varchar(255) null, ',...
            'hours int not null, N int not null, cs_mean double null, cs_median double null, ',...
            'cs_std double null, effect_size double null, ',...
            'es_n int not null)'],tablename_es));
    
        colnames_es = {'orf_name','hours','N',...
            'cs_mean','cs_median','cs_std',...
            'effect_size','es_n'};
        
        for ii = 1:length(hours)
            fit_cont{ii} = fetch(conn, sprintf(['select * from %s ',...
                'where hours = %d and orf_name = ''%s'''],...
                tablename_fits,hours(ii),cont.name));
            fit_orf{ii} = fetch(conn, sprintf(['select * from %s ',...
                'where hours = %d and orf_name != ''%s'' ',...
                'order by orf_name asc'],...
                tablename_fits,hours(ii),cont.name));
            
            for i = 1:length(fit_orf{ii}.orf_name)
                [fit_orf{ii}.effect_size(i,:), fit_orf{ii}.es_n(i,:)] = ...
                    effect_size(fit_cont{ii}.N,fit_cont{ii}.cs_mean,fit_cont{ii}.cs_std,...
                    fit_orf{ii}.N(i),fit_orf{ii}.cs_mean(i),fit_orf{ii}.cs_std(i),...
                    1.96,1.96);
            end
            tic
            sqlwrite(conn,tablename_es,fit_orf{ii});
            toc
        end

%%  FITNESS to PERC

%         exec(conn, sprintf('drop table %s',tablename_perc));
%         exec(conn, sprintf(['create table %s (hours int not null, ' ...
%             'perc5 double null, perc95 double null)'],tablename_perc));
%         
%         colnames_perc = {'hours','perc5','perc95'};
%     
%         for ii = 1:length(hours)
%             query = sprintf(['select orf_name, fitness ',...
%                 'from %s ',...
%                 'where hours = %d and orf_name is not NULL ',...
%                 'and orf_name = "%s"'],tablename_fit,hours(ii),cont.name);
%             contfit = fetch(conn, query);
%     
%         %     percdata.exp_id = 28;
%             percdata{ii}.hours  = hours(ii);
%             percdata{ii}.perc5  = prctile(contfit.fitness, 5);
%             percdata{ii}.perc95 = prctile(contfit.fitness, 95);
%             tic
%             datainsert(conn,tablename_perc,colnames_perc,percdata{ii});
%             toc
%         end

%%  EMPIRICAL FDR

%         exec(conn, sprintf('drop table %s',tablename_efdr));
%         exec(conn, sprintf(['create table %s (hours int not null, ' ...
%             'p double null, eFDR double null)'],tablename_efdr));
%         
%         colnames_efdr = {'hours','p','eFDR'};
%         
%         efdrdata = efdr(tablename_fit,tablename_pval,hours,cont.name,16);
%         
%         datainsert(conn,tablename_efdr,colnames_efdr,efdrdata);

%%  EMPIRICAL P-VALUES to EMPIRICAL FDR 

%         exec(conn, sprintf('drop table %s',tablename_efdr2));
%         exec(conn, sprintf(['create table %s (orf_name varchar(255) not null, ',...
%             'hours int not null, p double null, stat double null, ',...
%             'eFDR double null)'],tablename_efdr2));
%         colnames_efdr2 = {'orf_name','hours','p','stat','eFDR'};
%         
%         efdrdata2 = efdr2(tablename_pval,hours,cont.name);
%     
%         tic
%         for ii = 1:length(hours)
%             datainsert(conn,tablename_efdr2,colnames_efdr2,efdrdata2{ii});
%         end
%         toc
%      
%%  RESULTS USING PERC METHOD

%         exec(conn, sprintf('drop table %s',tablename_res));
%         exec(conn, sprintf(['create table %s (orf_name varchar(255) not null, ',...
%             'hours int not null, cs_median double null, ',...
%             'q double null, effect_cs int not null, protogene int not null)'],tablename_res));
%         
%         colnames_res = {'orf_name','hours','cs_median','q','effect_cs','protogene'};
%     
%         for ii = 1:length(hours)
%             query = sprintf(['select a.orf_name, a.hours, a.cs_median, c.q ',...
%                 'from %s a, %s b, %s c ',...
%                 'where a.hours = %d and a.hours = b.hours and a.hours = c.hours ',...
%                 'and a.orf_name = c.orf_name ',...
%                 'and a.cs_median >= b.perc95 and c.q <= 0.01 ',...
%                 'order by a.cs_median asc'],tablename_fits,tablename_perc,...
%                 tablename_qval,hours(ii));
%             ben = fetch(conn, query);
%             if isempty(ben) ~= 1
%                 ben.effect_cs = ones(length(ben.orf_name),1);
%                 ben.protogene = ismember(ben.orf_name, proto.orf_name);
%                 datainsert(conn,tablename_res,colnames_res,ben);
%             end
%             
%             query = sprintf(['select a.orf_name, a.hours, a.cs_median, c.q ',...
%                 'from %s a, %s b, %s c ',...
%                 'where a.hours = %d and a.hours = b.hours and a.hours = c.hours ',...
%                 'and a.orf_name = c.orf_name ',...
%                 'and a.cs_median <= b.perc5 and c.q <= 0.01 ',...
%                 'order by a.cs_median asc'],tablename_fits,tablename_perc,...
%                 tablename_qval,hours(ii));
%             del = fetch(conn, query);   
%             if isempty(del) ~= 1
%                 del.effect_cs = ones(length(del.orf_name),1).*-1;
%                 del.protogene = ismember(del.orf_name, proto.orf_name);
%                 datainsert(conn,tablename_res,colnames_res,del);
%             end
%             
%             query = sprintf(['select a.orf_name, a.hours, a.cs_median, c.q ',...
%                 'from %s a, %s b, %s c ',...
%                 'where a.hours = %d and a.hours = b.hours and a.hours = c.hours ',...
%                 'and a.orf_name = c.orf_name and a.cs_median ',...
%                 'and a.orf_name not in ',...
%                 '(select orf_name from %s ',...
%                 'where hours = %d) ',...
%                 'order by a.cs_median asc'],tablename_fits,tablename_perc,...
%                 tablename_qval,hours(ii),tablename_res,hours(ii));
%             neut = fetch(conn, query);     
%             if isempty(neut) ~= 1
%                 neut.effect_cs = zeros(length(neut.orf_name),1);
%                 neut.protogene = ismember(neut.orf_name, proto.orf_name);
%                 datainsert(conn,tablename_res,colnames_res,neut);
%             end
%         end

%%  RESULTS using EFFECT SIZE

%         exec(conn, sprintf('drop table %s',tablename_res_es));
%         exec(conn, sprintf(['create table %s (orf_name varchar(255) not null, ',...
%             'hours int not null, N int not null, cs_mean double null, ',...
%             'cs_std double null, effect_size double null, es_n int not null, ',...
%             'q double null, effect_cs int not null, protogene int not null)'],tablename_res_es));
%         
%         colnames_res_es = {'orf_name','hours','N',...
%             'cs_mean','cs_std','effect_size','es_n',...
%             'q','effect_cs','protogene'};
%     
%         for ii = 1:length(hours)
%             query = sprintf(['select a.orf_name, a.hours, a.N, a.cs_mean, '...
%                 'a.cs_std, a.effect_size, a.es_n, b.q ',...
%                 'from %s a, %s b ',...
%                 'where a.hours = %d and a.hours = b.hours ',...
%                 'and a.effect_size > 0.8 and a.N >= a.es_n ',...
%                 'and a.orf_name = b.orf_name and b.q <= 0.01 ',...
%                 'and b.stat > 0 ',...
%                 'order by a.cs_mean asc'],tablename_es,...
%                 tablename_qval,hours(ii));
%             ben_es = fetch(conn, query);    
%             if isempty(ben_es) ~= 1
%                 ben_es.effect_cs = ones(length(ben_es.orf_name),1);
%                 ben_es.protogene = ismember(ben_es.orf_name, proto.orf_name);
%                 datainsert(conn,tablename_res_es,colnames_res_es,ben_es);
%             end
%             
%             query = sprintf(['select a.orf_name, a.hours, a.N, a.cs_mean, '...
%                 'a.cs_std, a.effect_size, a.es_n, b.q ',...
%                 'from %s a, %s b ',...
%                 'where a.hours = %d and a.hours = b.hours ',...
%                 'and a.effect_size > 0.8 and a.N >= a.es_n ',...
%                 'and a.orf_name = b.orf_name and b.q <= 0.01 ',...
%                 'and b.stat < 0 ',...
%                 'order by a.cs_mean asc'],tablename_es,...
%                 tablename_qval,hours(ii));
%             del_es = fetch(conn, query);    
%             if isempty(del_es) ~= 1
%                 del_es.effect_cs = ones(length(del_es.orf_name),1).*-1;
%                 del_es.protogene = ismember(del_es.orf_name, proto.orf_name);
%                 datainsert(conn,tablename_res_es,colnames_res_es,del_es);
%             end
%             
%             query = sprintf(['select a.orf_name, a.hours, a.N, a.cs_mean, '...
%                 'a.cs_std, a.effect_size, a.es_n, b.q ',...
%                 'from %s a, %s b ',...
%                 'where a.hours = %d and a.hours = b.hours ',...
%                 'and a.orf_name = b.orf_name ',...
%                 'and a.orf_name not in ',...
%                 '(select orf_name from %s ',...
%                 'where hours = %d) ',...
%                 'order by a.cs_mean asc'],tablename_es,...
%                 tablename_qval,hours(ii),tablename_res_es,hours(ii));
%             neut_es = fetch(conn, query);     
%             if isempty(neut) ~= 1
%                 neut_es.effect_cs = zeros(length(neut_es.orf_name),1);
%                 neut_es.protogene = ismember(neut_es.orf_name, proto.orf_name);
%                 datainsert(conn,tablename_res_es,colnames_res_es,neut_es);
%             end
%         end

    %%  RESULTS using q values and eFDR

        exec(conn, sprintf('drop table %s',tablename_res_efdr));
        exec(conn, sprintf(['create table %s (orf_name varchar(255) not null, ',...
            'hours int not null, N int not null, cs_median double null, ',...
            'p double null, q double null, ',...
            'effect_cs int not null, protogene int not null)'],tablename_res_efdr));

        colnames_res_efdr = {'orf_name','hours','N',...
            'cs_median','p','q','effect_cs','protogene'};

        for ii = 1:length(hours)
            query = sprintf(['select a.orf_name, a.hours, b.N, b.cs_median, a.p, a.q ',...
                'from %s a, %s b ',...
                'where a.hours = %d and b.hours = a.hours ',...
                'and a.orf_name = b.orf_name and a.stat > 0 ',...
                'and a.q <= 0.05 ',...
                'order by cs_median desc'],tablename_qval,tablename_fits,...
                hours(ii));
            ben_efdr = fetch(conn, query);    
            if isempty(ben_efdr) ~= 1
                ben_efdr.effect_cs = ones(length(ben_efdr.orf_name),1);
                ben_efdr.protogene = ismember(ben_efdr.orf_name, proto.orf_name);
                datainsert(conn,tablename_res_efdr,colnames_res_efdr,ben_efdr);
            end

            query = sprintf(['select a.orf_name, a.hours, b.N, b.cs_median, a.p, a.q ',...
                'from %s a, %s b ',...
                'where a.hours = %d and b.hours = a.hours ',...
                'and a.orf_name = b.orf_name and a.stat < 0 ',...
                'and a.q <= 0.05 ',...
                'order by cs_median desc'],tablename_qval,tablename_fits,...
                hours(ii));
            del_efdr = fetch(conn, query);    
            if isempty(del_efdr) ~= 1
                del_efdr.effect_cs = ones(length(del_efdr.orf_name),1).*-1;
                del_efdr.protogene = ismember(del_efdr.orf_name, proto.orf_name);
                datainsert(conn,tablename_res_efdr,colnames_res_efdr,del_efdr);
            end

            query = sprintf(['select a.orf_name, a.hours, a.N, a.cs_median, '...
                'b.p, b.q ',...
                'from %s a, %s b ',...
                'where a.hours = %d and a.hours = b.hours ',...
                'and a.orf_name = b.orf_name ',...
                'and a.orf_name not in ',...
                '(select orf_name from %s ',...
                'where hours = %d) ',...
                'order by a.cs_median desc'],tablename_fits,...
                tablename_qval,hours(ii),tablename_res_efdr,hours(ii));
            neut_efdr = fetch(conn, query);     
            if isempty(neut_efdr) ~= 1
                neut_efdr.effect_cs = zeros(length(neut_efdr.orf_name),1);
                neut_efdr.protogene = ismember(neut_efdr.orf_name, proto.orf_name);
                datainsert(conn,tablename_res_efdr,colnames_res_efdr,neut_efdr);
            end
        end
        
%%  END OF ANALYSIS
    end

%%
    conn(close);

%%  BEN, DEL and NEUT using ES

% % stat > 0              es > 2        strong beneficial
% %                 1.4 < es <= 2       beneficial
% %                 0.8 < es <= 1.4     mild beneficial
% %             
% % stat < 0              es > 2        strong deleterious
% %                 1.4 < es <= 2       deleterious
% %                 0.8 < es <= 1.4     mild deleterious
% %             
% % everything else                     neutral
    
%%  END