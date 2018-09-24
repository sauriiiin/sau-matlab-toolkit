%%  Sau MATLAB Colony Analyzer Toolkitv
%
%%  pos2coor2strainid.m

%   Author: Saurin Parikh, September 2018
%   dr.saurin.parikh@gmail.com

%%  INITIALIZATION
    
    prompt={'Enter a name for your experiment:'};
    name='expt_name';
    numlines=1;
    defaultanswer={'test'};
    expt_name = char(inputdlg(prompt,name,numlines,defaultanswer));
    
    tablename_p2id      = sprintf('%s_pos2strainid',expt_name);
    colnames_p2id       = {'pos','strain_id'};
    tablename_p2c384    = sprintf('%s_pos2coor384',expt_name);
    colnames_p2c384     = {'pos','384plate','384row','384col'};
    tablename_p2c1536   = sprintf('%s_pos2coor1536',expt_name);
    colnames_p2c1536    = {'pos','1536plate','1536row','1536col'};    
    tablename_p2c6144   = sprintf('%s_pos2coor6144',expt_name);
    colnames_p2c6144    = {'pos','6144plate','6144row','6144col'};
    tablename_p2o       = sprintf('%s_pos2orf_name',expt_name);
    
%%  INDICES

    coor6144 = [];
    coor1536 = [];
    coor384 = [];

    for i = linspace(1,3,3)
        coor6144 = [coor6144, [ones(1,6144)*i;indices(6144)]];
    end

    for i = linspace(1,4,4)
        coor1536 = [coor1536, [ones(1,1536)*i;indices(1536)]];
    end

    for i = [3,5,22,19]
        coor384 = [coor384, [ones(1,384)*i;indices(384)]];
    end

%%  STRAINS

    connectSQL;

    plates = fetch(conn, ['select distinct 384plate ',...
        'from BARFLEX_SPACE_AGAR where 384plate in (3,5,22) ',...
        'order by 384plate asc']);

    strains = [-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2];

    data = [];
    for i=1:length(plates.x384plate)
        bf = fetch(conn, sprintf(['select * from BARFLEX_SPACE_AGAR ',...
            'where 384plate = %d ',...
            'order by 384plate, 384col, 384row'],plates.x384plate(i)));
        pos     = linspace(384*(i-1)'+1,384*i,384)';
        plate   = ones(384,1)*plates.x384plate(i);
        coor    = indices(384)';

        temp    = [pos, plate, coor, strains];

            for ii=1:length(bf.strain_id)
                temp(bf.x384row(ii) + 16*(bf.x384col(ii)-1),5) = bf.strain_id(ii);
            end
            
        data = [data;[temp(:,1),temp(:,5)]];
    end
    
    exec(conn, sprintf(['create table %s ',...
        '(pos int not null, strain_id int not null)'], tablename_p2id));

    %strains
    datainsert(conn,tablename_p2id,colnames_p2id,data);
    %control plate
    c_data = [linspace(384*3+1,384*4,384)',ones(384,1)*-1];
    datainsert(conn,tablename_p2id,colnames_p2id,c_data);

%%  POSITIONS

%   plate384 positions/plate
    pos384_03    = col2grid(linspace(1,384,384));
    pos384_05    = col2grid(linspace(384+1,384*2,384));
    pos384_22    = col2grid(linspace(384*2+1,384*3,384));
    pos384_c1    = col2grid(linspace(384*3+1,384*4,384));
%   plate384 positions+indices/plate
    plate384    = [[grid2row(pos384_03), grid2row(pos384_05),...
        grid2row(pos384_22), grid2row(pos384_c1)]; coor384]';
    
    exec(conn, sprintf(['create table %s (pos int not null, ',...
        '384plate int not null,'...
        ' 384row int not null, 384col int not null)']),tablename_p2c384);
    datainsert(conn,tablename_p2c384,colnames_p2c384,plate384);

%   plate1536 positions/plate
    pos1536_1 = plategen(pos384_c1,pos384_03,pos384_05,pos384_22)+10000;
    pos1536_2 = plategen(pos384_22,pos384_c1,pos384_03,pos384_05)+20000;
    pos1536_3 = plategen(pos384_05,pos384_22,pos384_c1,pos384_03)+30000;
    pos1536_4 = plategen(pos384_03,pos384_05,pos384_22,pos384_c1)+40000;
%   plate1536 positions+indices/plate    
    plate1536   = [[grid2row(pos1536_1), grid2row(pos1536_2),...
        grid2row(pos1536_3), grid2row(pos1536_4)]; coor1536]';    
    
    exec(conn, sprintf(['create table %s (pos int not null, ',...
        '1536plate int not null, '...
        '1536row int not null, 1536col int not null)'],tablename_p2c1536));
    datainsert(conn,tablename_p2c1536,colnames_p2c1536,plate1536);    
    
%   plate6144 positions/plate
    pos6144_1 = plategen(pos1536_1,pos1536_2,pos1536_3,pos1536_4)+100000;
    pos6144_2 = plategen(pos1536_1,pos1536_2,pos1536_3,pos1536_4)+200000;
    pos6144_3 = plategen(pos1536_1,pos1536_2,pos1536_3,pos1536_4)+300000;
%   plate6144 positions+indices/plate    
    plate6144   = [[grid2row(pos6144_1),grid2row(pos6144_2),...
        grid2row(pos6144_3)]; coor6144]';
    
    exec(conn, sprintf(['create table %s (pos int not null,',...
        ' 6144plate int not null,'...
        ' 6144row int not null, 6144col int not null)'],tablename_p2c6144));
    datainsert(conn,tablename_p2c6144,colnames_p2c6144,plate6144);
   
%%  CALCULATING STRAINS FOR P2ID TABLES

%   plate384 pos2strainid
    strain384_3    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 1 and 384',...
        ' order by pos asc'],tablename_p2id));
    strain384_3 = col2grid(strain384_3.strain_id);

    strain384_5    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 385 and 384*2',...
        ' order by pos asc'],tablename_p2id));
    strain384_5    = col2grid(strain384_5.strain_id);
    
    strain384_22    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 384*2+1 and 384*3',...
        ' order by pos asc'],tablename_p2id));
    strain384_22   = col2grid(strain384_22.strain_id);

    strain384_c    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 384*3+1 and 384*4',...
        ' order by pos asc'],tablename_p2id));
    strain384_c    = col2grid(strain384_c.strain_id);

%   plate1536 pos2strainid
    strain1536_1 = plategen(strain384_c,strain384_3,strain384_5,strain384_22);
    strain1536_2 = plategen(strain384_22,strain384_c,strain384_3,strain384_5);
    strain1536_3 = plategen(strain384_5,strain384_22,strain384_c,strain384_3);
    strain1536_4 = plategen(strain384_3,strain384_5,strain384_22,strain384_c);
    
    strain1536   = [plate1536(:,1)';[grid2row(strain1536_1), grid2row(strain1536_2),...
        grid2row(strain1536_3), grid2row(strain1536_4)]]';    
    
    datainsert(conn,tablename_p2id,colnames_p2id,strain1536);    
    
%   plate6144 pos2strainid
    strain6144 = plategen(strain1536_1,strain1536_2,strain1536_3,strain1536_4);
    
    strain6144   = [plate6144(:,1)'; [grid2row(strain6144),...
        grid2row(strain6144),grid2row(strain6144)]]';
    
    datainsert(conn,tablename_p2id,colnames_p2id,strain6144);
    
%%  POS2ORF_NAME TABLE USING SQL DATA

    exec(conn, sprintf('drop table %s',tablename_p2o)); 
    exec(conn, sprintf(['create table %s',...
        ' (select a.pos, b.orf_name',...
        ' from %s a, BARFLEX_SPACE_AGAR b',...
        ' where a.strain_id = b.strain_id)'],tablename_p2o,tablename_p2id));
    
%%  END
    conn(close);


