%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  pos2coor2strainid.m

%   Author: Saurin Parikh, September 2018
%   dr.saurin.parikh@gmail.com
%  
%   Create position 2 co-ordinate, 2 strain id and
%       2 orf_name tables for any experiment.

%%  INITIALIZATION

%     Set preferences with setdbprefs.
    setdbprefs({'NullStringRead';'NullStringWrite';'NullNumberRead';'NullNumberWrite'},...
                  {'null';'null';'NaN';'NaN'})
    connectSQL;
    
    prompt={'Enter a name for your experiment:'};
    name='expt_name';
    numlines=1;
    defaultanswer={'test'};
    expt_name = char(inputdlg(prompt,name,numlines,defaultanswer));
    
    tablename_p2id      = sprintf('%s_pos2strainid',expt_name);
    colnames_p2id       = {'pos','strain_id'};
    tablename_p2c96     = sprintf('%s_pos2coor96',expt_name);
    colnames_p2c96      = {'pos','96plate','96row','96col'};
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
    coor384  = [];
    coor96   = [];

    for i = linspace(1,2,2)             %modify this
        coor6144 = [coor6144, [ones(1,6144)*i;indices(6144)]];
    end

    for i = linspace(1,4,4)             %modify this
        coor1536 = [coor1536, [ones(1,1536)*i;indices(1536)]];
    end

    for i = linspace(1,4,4)  %i = [3,5,22,19]  %modify this
        coor384 = [coor384, [ones(1,384)*i;indices(384)]];
    end
    
    for i = linspace(1,2,2)  %i = [3,5,22,19]  %modify this
        coor96 = [coor96, [ones(1,96)*i;indices(96)]];
    end

%%  STRAINS
%%  START WITH A CUSTOM 96

%   PLATE 96
%     plate96_01 = []; % and copy paste data from the excel sheet for the experimental layout

    exec(conn, sprintf(['create table %s ',...
        '(pos int not null, strain_id int not null)'], tablename_p2id));
    
    data = [linspace(1,96*2,96*2);...
        [grid2row(plate96_01),grid2row(plate96_02)]]';
    datainsert(conn,tablename_p2id,colnames_p2id,data);
    
%   PLATE 384
    
%%  START WITH EXISTING 384

%     plates = fetch(conn, ['select distinct 384plate ',...
%         'from BARFLEX_SPACE_AGAR where 384plate in (3,5,22) ',...
%         'order by 384plate asc']);
%     %borders and nulls
%     strains = [-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;0;0;0;0;0;0;0;0;0;0;0;0;0;0;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2;-2];
% 
%     data = [];
%     for i=1:length(plates.x384plate)
%         bf = fetch(conn, sprintf(['select * from BARFLEX_SPACE_AGAR ',...
%             'where 384plate = %d ',...
%             'order by 384plate, 384col, 384row'],plates.x384plate(i)));
%         pos     = linspace(384*(i-1)'+1,384*i,384)';
%         plate   = ones(384,1)*plates.x384plate(i);
%         coor    = indices(384)';
% 
%         temp    = [pos, plate, coor, strains];
% 
%             for ii=1:length(bf.strain_id)
%                 temp(bf.x384row(ii) + 16*(bf.x384col(ii)-1),5) = bf.strain_id(ii);
%             end
%             
%         data = [data;[temp(:,1),temp(:,5)]];
%     end
%     
%     exec(conn, sprintf(['create table %s ',...
%         '(pos int not null, strain_id int not null)'], tablename_p2id));
% 
%     %strains
%     datainsert(conn,tablename_p2id,colnames_p2id,data);
%     %control plate
%     c_data = [linspace(384*3+1,384*4,384)',ones(384,1)*-1];
%     datainsert(conn,tablename_p2id,colnames_p2id,c_data);

%%  POSITIONS

%   plate384 positions/plate
    pos384_X  = col2grid(linspace(1,384,384));
    pos384_Y  = col2grid(linspace(384+1,384*2,384));
    pos384_Z  = col2grid(linspace(384*2+1,384*3,384));
    pos384_C  = col2grid(linspace(384*3+1,384*4,384));
%   plate384 positions+indices/plate
    plate384  = [[grid2row(pos384_X), grid2row(pos384_Y),...
        grid2row(pos384_Z), grid2row(pos384_C)]; coor384]';
    
    exec(conn, sprintf(['create table %s (pos int not null, ',...
        '384plate int not null, '...
        '384row int not null, 384col int not null)'],tablename_p2c384));
    datainsert(conn,tablename_p2c384,colnames_p2c384,plate384);

%   plate1536 positions/plate
    pos1536_K = plategen(pos384_C,pos384_X,pos384_Y,pos384_Z)+10000;
    pos1536_L = plategen(pos384_Z,pos384_C,pos384_X,pos384_Y)+20000;
    pos1536_M = plategen(pos384_Y,pos384_Z,pos384_C,pos384_X)+30000;
    pos1536_N = plategen(pos384_X,pos384_Y,pos384_Z,pos384_C)+40000;
%   plate1536 positions+indices/plate    
    plate1536 = [[grid2row(pos1536_K), grid2row(pos1536_L),...
        grid2row(pos1536_M), grid2row(pos1536_N)]; coor1536]';    
    
    exec(conn, sprintf(['create table %s (pos int not null, ',...
        '1536plate int not null, '...
        '1536row int not null, 1536col int not null)'],tablename_p2c1536));
    datainsert(conn,tablename_p2c1536,colnames_p2c1536,plate1536);    
    
%   plate6144 positions/plate
    pos6144_P = plategen(pos1536_K,pos1536_L,pos1536_M,pos1536_N)+100000;
    pos6144_Q = plategen(pos1536_N,pos1536_K,pos1536_L,pos1536_M)+200000;
%     pos6144_M = plategen(pos1536_K,pos1536_L,pos1536_M,pos1536_N)+300000;
%   plate6144 positions+indices/plate    
    plate6144 = [[grid2row(pos6144_P),grid2row(pos6144_Q)]; coor6144]';
    
    exec(conn, sprintf(['create table %s (pos int not null,',...
        ' 6144plate int not null,'...
        ' 6144row int not null, 6144col int not null)'],tablename_p2c6144));
    datainsert(conn,tablename_p2c6144,colnames_p2c6144,plate6144);
   
%%  CALCULATING STRAINS FOR POS2STRAIN_ID TABLES

%   plate384 pos2strainid
    strain384_X    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 1 and 384',...
        ' order by pos asc'],tablename_p2id));
    strain384_X = col2grid(strain384_X.strain_id);

    strain384_Y    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 385 and 384*2',...
        ' order by pos asc'],tablename_p2id));
    strain384_Y    = col2grid(strain384_Y.strain_id);
    
    strain384_Z    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 384*2+1 and 384*3',...
        ' order by pos asc'],tablename_p2id));
    strain384_Z   = col2grid(strain384_Z.strain_id);

    strain384_C    = fetch(conn, sprintf(['select strain_id from %s',...
        ' where pos between 384*3+1 and 384*4',...
        ' order by pos asc'],tablename_p2id));
    strain384_C    = col2grid(strain384_C.strain_id);

%   plate1536 pos2strainid
    strain1536_K = plategen(strain384_C,strain384_X,strain384_Y,strain384_Z);
    strain1536_L = plategen(strain384_Z,strain384_C,strain384_X,strain384_Y);
    strain1536_M = plategen(strain384_Y,strain384_Z,strain384_C,strain384_X);
    strain1536_N = plategen(strain384_X,strain384_Y,strain384_Z,strain384_C);
    
    strain1536   = [plate1536(:,1)';[grid2row(strain1536_K), grid2row(strain1536_L),...
        grid2row(strain1536_M), grid2row(strain1536_N)]]';    
    
    datainsert(conn,tablename_p2id,colnames_p2id,strain1536);    
    
%   plate6144 pos2strainid
    strain6144_P = plategen(strain1536_K,strain1536_L,strain1536_M,strain1536_N);
    strain6144_Q = plategen(strain1536_N,strain1536_K,strain1536_L,strain1536_M);
    
    strain6144   = [plate6144(:,1)';...
        [grid2row(strain6144_P),grid2row(strain6144_Q)]]';
    
    datainsert(conn,tablename_p2id,colnames_p2id,strain6144);
    
%%  POS2ORF_NAME TABLE USING SQL DATA

    exec(conn, sprintf('drop table %s',tablename_p2o)); 
    exec(conn, sprintf(['create table %s',...
        ' (select a.pos, b.orf_name',...
        ' from %s a, BARFLEX_SPACE_AGAR b',...
        ' where a.strain_id = b.strain_id)'],tablename_p2o,tablename_p2id));
    
%%  END
    conn(close);
%%