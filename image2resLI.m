%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  image2resLI.m

%   Author: Saurin Parikh, February 2019
%   dr.saurin.parikh@gmail.com
%   
%   Analyze Images -> Upload Data
%   and then
%   JPEG data to Q-VALUES for any experiment with Linear Interpolation 
%   based Control Normalization.
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
    tablename_ibg       = sprintf('%s_%d_iBG',expt_name,density);
    tablename_spa       = sprintf('%s_%d_SPATIAL',expt_name, density);
    tablename_fit       = sprintf('%s_%d_FITNESS',expt_name,density);
    tablename_fits      = sprintf('%s_%d_FITNESS_STATS',expt_name,density);
    tablename_es        = sprintf('%s_%d_FITNESS_ES',expt_name,density);
    tablename_pval      = sprintf('%s_%d_PVALUE',expt_name,density);
    tablename_epval     = sprintf('%s_%d_EPVALUE',expt_name,density);
    tablename_qval      = sprintf('%s_%d_QVALUE',expt_name,density);
    tablename_perc      = sprintf('%s_%d_PERC',expt_name,density);
    tablename_efdr      = sprintf('%s_%d_eFDR',expt_name,density);
    tablename_res       = sprintf('%s_%d_RES',expt_name,density);
    tablename_res_es    = sprintf('%s_%d_RES_ES',expt_name,density);
    tablename_res_efdr  = sprintf('%s_%d_RES_eFDR',expt_name,density);
    
%   MySQL Connection and fetch initial data

    connectSQL;
    
%     prompt={'Enter the name of your P2C Table:',...
%         'Name of the "Plate" column:',...
%         'Name of the "Column" column:',...
%         'Name of the "Row" column:'};
%     name='P2C Table Info';
%     defaultanswers={'expt_pos2coor','384plate','384col','384row'};
%     p2c_info = char(inputdlg(prompt,...
%         name,1,defaultanswers));
    
    p2c_info(1,:) = 'PT2_pos2coor6144';
    p2c_info(2,:) = '6144plate       ';
    p2c_info(3,:) = '6144col         ';
    p2c_info(4,:) = '6144row         ';

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
    
%     prompt={'Enter the Smudge Box Table Name:'};
%     tablename_sbox = char(inputdlg(prompt,...
%         'Smudge Box',1,...
%         {'expt_smudgebox'}));
    
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

%%  SPATIAL CLEAN UP
%   Border colonies, light artefact and smudge correction

        exec(conn, sprintf(['update %s ',...
            'set average = NULL ',...
            'where pos in ',...
            '(select pos from %s)'],tablename_jpeg,tablename_bpos));
        
        exec(conn, sprintf(['update %s ',...
            'set average = NULL ',...
            'where average <= 10'],tablename_jpeg));
        
        exec(conn, sprintf(['update %s ',...
            'set average = NULL ',...
            'where pos in ',...
            '(select pos from %s)'],tablename_jpeg,tablename_sbox));
    
%%  Upload JPEG Data to RAW with Linear Interpolation based CN





