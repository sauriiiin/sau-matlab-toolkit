%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  fitnessfinder.m

%   Author: Saurin Parikh, April 2018
%   dr.saurin.parikh@gmail.com

%   Automated script for Nelson and John to use during summer'18 for analyzing
%   the results from the Mini Screens that are planned.

%%  Load Paths to Files and Data

    col_analyzer_path = '/users/saurinparikh/documents/matlab/matlab-colony-analyzer-toolkit-master';
    bean_toolkit_path = '/users/saurinparikh/documents/matlab/bean-matlab-toolkit-master';
    sau_toolkit_path = '/users/saurinparikh/documents/matlab/sau-matlab-toolkit';
    addpath(genpath(col_analyzer_path));
    addpath(genpath(bean_toolkit_path));
    addpath(genpath(sau_toolkit_path));
%     javaaddpath(uigetfile());

%%  Add MCA toolkit to Path
    add_mca_toolkit_to_path
    
%%  Initialize

%   Expt Name
    prompt={'Enter a name for your experiment:'};
    name='expt_name';
    numlines=1;
    defaultanswer={'test'};
    expt_name = char(inputdlg(prompt,name,numlines,defaultanswer));

%   Choose folder
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
    
%   Density of the plates
    density = str2num(questdlg('What density plates are you using?',...
        'Density Options',...
        '1536','6144','6144'));
    
    if density == 6144
        dimensions = [64 96];
    else
        dimensions = [32 48];
    end
    
%     prompt={'Enter the number of replicates in this study:'};
%     replicate = str2num(cell2mat(inputdlg(prompt,...
%         'Replicates',1,...
%         {'4'})));
    
%   Table names
    tablename_jpeg      = sprintf('%s_%d_JPEG',expt_name,density); 
    tablename_raw       = sprintf('%s_%d_RAW',expt_name,density); 
    tablename_spa       = sprintf('%s_%d_SPATIAL',expt_name, density);
    tablename_fit       = sprintf('%s_%d_FITNESS',expt_name,density);
    tablename_fits      = sprintf('%s_%d_FITNESS_STATS',expt_name,density);
    tablename_pval      = sprintf('%s_%d_PVALUE',expt_name,density);
    tablename_res       = sprintf('%s_%d_RES',expt_name,density);

%   Connection details
    connectSQL;
   
%   pos2coor table    
    p2c_info = [['MS_pos2coor', num2str(density)];...
        [num2str(density), 'plate      '];...
        [num2str(density), 'col        '];...
        [num2str(density), 'row        ']];
    
    p2c = fetch(conn, sprintf(['select * from %s a ',...
        'order by a.%s, a.%s, a.%s'],...
        p2c_info(1,:),...
        p2c_info(2,:),...
        p2c_info(3,:),...
        p2c_info(4,:)));
    
%   other details
    tablename_p2o   = 'MS_pos2orf_name';
    cont.name       = 'BF_control';
    tablename_bpos  = 'MS_borderpos';
    proto           = fetch(conn, ['select orf_name from PROTOGENES ',...
        'where longer + selected + translated < 3']);
    
%%  Load data

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
    
    exec(conn, sprintf('drop table %s',tablename_raw));  
    exec(conn, sprintf(['create table %s (pos int not null, hours int not null,'...
        'replicate1 int not null,'...
        'replicate2 int not null, replicate3 int not null, average double not null,'...
        'csS double not null, csM double not null)'], tablename_raw));
      
    colnames_raw = {'pos','hours'...
        'replicate1','replicate2','replicate3',...
        'average','csS','csM'};
    
    avg_data = ControlNorm(density,tablename_jpeg,tablename_p2o,p2c_info,cont.name);

    for ii = 1:length(avg_data)
        for iii = 1:length(avg_data{ii})
            if ~isempty(avg_data{ii}{iii})
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
        
%         Cleanning RAW DATA
%         [n_plate, density] = detect_den(dimensions, data{ii}.pos);
%         rep_data = [data{ii}.replicate1, data{ii}.replicate2,...
%             data{ii}.replicate3];
%         [cleaned_rep_data, data{ii}.average] = ...
%                 clean_raw_data(rep_data, n_plate, density, 30);
%         data{ii}.replicate1 = cleaned_rep_data(:,1);
%         data{ii}.replicate2 = cleaned_rep_data(:,2);
%         data{ii}.replicate3 = cleaned_rep_data(:,3); 
        
%         Avoiding light artefact
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
        
%         NULLs from BORDERS
        borders = fetch(conn, sprintf('select pos from %s',...
            tablename_bpos));
        borders = borders.pos;
        [la, lb] = ismember(borders, data{ii}.pos);
        borders = lb(la);
        data{ii}.average(borders) = 99999;
        data{ii}.csS(borders) = 99999;
        data{ii}.csM(borders) = 99999;

% %         NULLs from SMUDGE BOX
%         smudge = fetch(conn, sprintf('select pos from %s',...
%             tablename_sbox));
%         smudge = smudge.pos;
%         [la, lb] = ismember(smudge, data{ii}.pos);
%         smudge = lb(la);
%         data{ii}.average(smudge) = 99999;
%         data{ii}.csS(smudge) = 99999;
%         data{ii}.csM(smudge) = 99999;
% %         
% % %         NULLs from Source Plates
%         source_zeros = [];
%         for i = 1:replicate
%             [la, lb] = ismember(source_nulls.pos, data{ii}.pos - (10000*i));%-(200000 + (10000*i)));
% %              source_zeros = [source_zeros;data{ii}.pos(la)];
%             source_zeros = lb(la);
%             data{ii}.average(source_zeros) = 99999;
%             data{ii}.csS(source_zeros) = 99999;
%             data{ii}.csM(source_zeros) = 99999;
%         end

        tic
        datainsert(conn,tablename_spa,colnames_spa,data{ii}); 
        toc
    end
    
%%  SPATIAL to FITNESS
    
    if density == 1536
        poslim = [10000,100000];
    elseif density == 6144
        poslim = [100000,1000000];
    else
        poslim = [0,10000];
    end

    orf_data = fetch(conn, sprintf(['select * from %s where pos between ',...
        '%d and %d'],tablename_p2o, poslim(1), poslim(2)));
    pos = orf_data.pos;
    orf_names = orf_data.orf_name;
%     orf_names = [orf_names; orf_names; orf_names; orf_names];
    
    exec(conn, sprintf('drop table %s',tablename_fit));
    exec(conn, sprintf(['create table %s (orf_name varchar(255) null, ',...
        'pos int not null, hours int not null, average double null, ',...
        'fitness double null)'],tablename_fit));

    colnames_fit = {'orf_name','pos','hours',...
        'average','fitness'};
    
    for ii = 1:length(hours)
        spatial = fetch(conn, sprintf(['select pos, hours, average, csS from ',...
            '%s where hours = %d ',...
            'order by pos'],tablename_spa,hours(ii)));
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
        'cs_median double null, cs_std double null, protogene int not null)'],tablename_fits));
    
    colnames_fits = {'orf_name','hours','N',...
        'cs_mean','cs_median','cs_std','protogene'};
    
    stat_data = fit_stats(tablename_fit);
    stat_data.protogene = ismember(stat_data.orf_name, proto.orf_name);
    
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
        datainsert(conn,tablename_pval,colnames_pval,pdata{ii});
        toc
    end

%%  RESULTS using eFDR
%   (p val < 0.05 and stat)

    exec(conn, sprintf('drop table %s',tablename_res));
    exec(conn, sprintf(['create table %s (orf_name varchar(255) not null, ',...
        'hours int not null, N int not null, cs_median double null, ',...
        'p double null, effect_cs int not null, protogene int not null)'],tablename_res));
    
    colnames_res_efdr = {'orf_name','hours','N',...
        'cs_median','p','effect_cs','protogene'};
    
    for ii = 1:length(hours)
        query = sprintf(['select a.orf_name, a.hours, b.N, b.cs_median, a.p ',...
            'from %s a, %s b ',...
            'where a.hours = %d and b.hours = a.hours ',...
            'and a.orf_name = b.orf_name and a.stat > 0 ',...
            'and a.p <= 0.05 ',...
            'order by cs_median desc'],tablename_pval,tablename_fits,...
            hours(ii));
        ben_efdr = fetch(conn, query);    
        if isempty(ben_efdr) ~= 1
            ben_efdr.effect_cs = ones(length(ben_efdr.orf_name),1);
            ben_efdr.protogene = ismember(ben_efdr.orf_name, proto.orf_name);
            datainsert(conn,tablename_res,colnames_res_efdr,ben_efdr);
        end
        
        query = sprintf(['select a.orf_name, a.hours, b.N, b.cs_median, a.p ',...
            'from %s a, %s b ',...
            'where a.hours = %d and b.hours = a.hours ',...
            'and a.orf_name = b.orf_name and a.stat < 0 ',...
            'and a.p <= 0.05 ',...
            'order by cs_median desc'],tablename_pval,tablename_fits,...
            hours(ii));
        del_efdr = fetch(conn, query);    
        if isempty(del_efdr) ~= 1
            del_efdr.effect_cs = ones(length(del_efdr.orf_name),1).*-1;
            del_efdr.protogene = ismember(del_efdr.orf_name, proto.orf_name);
            datainsert(conn,tablename_res,colnames_res_efdr,del_efdr);
        end
        
        query = sprintf(['select a.orf_name, a.hours, a.N, a.cs_median, '...
            'b.p ',...
            'from %s a, %s b ',...
            'where a.hours = %d and a.hours = b.hours ',...
            'and a.orf_name = b.orf_name ',...
            'and a.orf_name not in ',...
            '(select orf_name from %s ',...
            'where hours = %d) ',...
            'order by a.cs_median desc'],tablename_fits,...
            tablename_pval,hours(ii),tablename_res,hours(ii));
        neut_efdr = fetch(conn, query);     
        if isempty(neut_efdr) ~= 1
            neut_efdr.effect_cs = zeros(length(neut_efdr.orf_name),1);
            neut_efdr.protogene = ismember(neut_efdr.orf_name, proto.orf_name);
            datainsert(conn,tablename_res,colnames_res_efdr,neut_efdr);
        end
    end

%%  OUTPUT RESULTS

    clear stats effects spatial
   
    reshour = str2num(questdlg('What Time Point do you want the Results for?',...
        'Hour Options',...
        num2str(hours),...
        num2str(hours(end))));
    
    spatial = fetch(conn, sprintf(['select  c.orf_name, b.%s, b.%s, ',...
        'b.%s, a.average pixel_count, a.csS ',...
        'from %s a, %s b, %s c ',...
        'where a.hours = %d and a.pos = b.pos and b.pos = c.pos ',...
        'order by b.%s, b.%s, b.%s'],p2c_info(2,:),p2c_info(4,:),...
        p2c_info(3,:),tablename_spa,p2c_info(1,:),tablename_p2o,reshour,...
        p2c_info(2,:),p2c_info(3,:),p2c_info(4,:)));
    
    stats = fetch(conn, sprintf(['select * from %s ',...
        'where hours = %d'], tablename_fits, reshour));
    
    effect = fetch(conn, sprintf(['select * from %s ',...
        'where hours = %d'], tablename_res, reshour));
    
    struct2csv(spatial, [tmpdir,'/spatial_results.csv']);
    struct2csv(stats, [tmpdir,'/fitnessstats.csv']);
    struct2csv(effect, [tmpdir,'/fitnesseffect.csv']);
    
%%
    conn(close);
%%  THE END
    