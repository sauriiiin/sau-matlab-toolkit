%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  nullfinder.m

%   Author: Saurin Parikh, April 2018
%   dr.saurin.parikh@gmail.com

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

%%  Initialization

%     Set preferences with setdbprefs.
%     setdbprefs('DataReturnFormat', 'structure');
%     setdbprefs('NullNumberRead', 'NaN');
%     setdbprefs('NullStringRead', 'null');

    connectSQL;
    
%     Collecting all subfolders and files within them

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
    
    switch questdlg('Is it the entire BF Collection?',...
        'Options:',...
        'Yes','No','Yes')
        case 'Yes'
            plates = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,22';
        case 'No'
            plates = char(inputdlg('What plates do you have?',...
                'Plate Numbers',1,...
                {'1,2,3'}));
    end
    
    density = 384;
%     dimension = [16 24];

%     expt_name = 'TEMP';
    
    p2c = fetch(conn, sprintf(['select * from TEMP_pos2coor384 ',...
        'where 384plate in (%s) ',...
        'order by 384plate, 384col, 384row'],plates));
     
%%  LOADING ANALYZED DATA    
     
    cs = load_colony_sizes(files);
    
    cs_mean = [];
    tmp = cs';
    
    for ii = 1:3:length(files)
        cs_mean = [cs_mean, mean(tmp(:,ii:ii+2),2)];
    end
       
    cs_mean = cs_mean';
    
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

    exec(conn, 'drop table TEMP_384_JPEG');  
    exec(conn, ['create table TEMP_384_JPEG (pos int not null, hours int not null,'...
        'replicate1 int not null,'...
        'replicate2 int not null, replicate3 int not null, average double not null)']);
      
    colnames_jpeg = {'pos','hours'...
        'replicate1','replicate2','replicate3',...
        'average'};
    
    tmpdata = [];
    for ii=1:length(hours)
        tmpdata = [tmpdata; [p2c.pos, ones(length(p2c.pos),1)*hours(ii)]];
    end
    
    data = [tmpdata,master];
    tic
    datainsert(conn,'TEMP_384_JPEG',colnames_jpeg,data);
    toc    

    clear data master tmp cs cs_mean p2c;
    
%%  FIND THE NULLS

    query = sprintf(['select b.orf_name, ',...
        'a.384plate, a.384col, a.384row, ',...
        'c.average ',...
        'from ',...
        'TEMP_384_JPEG c, ',...
        'TEMP_pos2coor384 a, ',...
        'BARFLEX_SPACE_AGAR b ',...
        'where a.pos = c.pos ',...
        'and a.384plate in (%s) ',...
        'and a.384plate = b.384plate ',...
        'and a.384row = b.384row ',...
        'and a.384col = b.384col ',...
        'and c.average < 100 ',...
        'order by a.384plate asc, ',...
        'a.384col asc, a.384row asc'], plates);
    nulls = fetch(conn, query);
    
    struct2csv(nulls, [tmpdir,'/nulls.csv']);
 
%%
    conn(close);
%%  THE END
    
    