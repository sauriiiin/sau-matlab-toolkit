%%  pos2coor2strainid_MS.m

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

    %strains
    colnames = {'pos','strain_id'};
    datainsert(conn,'PT2_pos2strainid',colnames,data);
    %control plate
    c_data = [linspace(384*3+1,384*4,384)',ones(384,1)*-1];
    datainsert(conn,'PT2_pos2strainid',colnames,c_data);

%%  POSITIONS

%   positions/plate
    pos384_03    = col2grid(linspace(1,384,384));
    pos384_05    = col2grid(linspace(384+1,384*2,384));
    pos384_22    = col2grid(linspace(384*2+1,384*3,384));
    pos384_c1    = col2grid(linspace(384*3+1,384*4,384));
%   positions+indices/plate
    plate384    = [[grid2row(pos384_03), grid2row(pos384_05),...
        grid2row(pos384_22), grid2row(pos384_c1)]; coor384]';
    
    exec(conn, ['create table PT2_pos2coor384 (pos int not null, 384plate int not null,'...
        ' 384row int not null, 384col int not null)']);
    tablename = 'BF_pos2coor384';
    colnames = {'pos','384plate','384row','384col'};
    datainsert(conn,tablename,colnames,plate384);

%   plate1536
    pos1536_1 = plategen(pos384_c1,pos384_03,pos384_05,pos384_22)+10000;
    pos1536_2 = plategen(pos384_22,pos384_c1,pos384_03,pos384_05)+20000;
    pos1536_3 = plategen(pos384_05,pos384_22,pos384_c1,pos384_03)+30000;
    pos1536_4 = plategen(pos384_03,pos384_05,pos384_22,pos384_c1)+40000;
    
    plate1536   = [[grid2row(pos1536_1), grid2row(pos1536_2),...
        grid2row(pos1536_3), grid2row(pos1536_4)]; coor1536]';    
    
    exec(conn, ['create table MS_pos2coor1536 (pos int not null, 1536plate int not null,'...
        ' 1536row int not null, 1536col int not null)']);
    tablename = 'MS_pos2coor1536';
    colnames = {'pos','1536plate','1536row','1536col'};
    datainsert(conn,tablename,colnames,plate1536);    
    
%   plate6144
    pos6144 = plategen(pos1536_1,pos1536_2,pos1536_3,pos1536_4)+100000;
    
    plate6144   = [grid2row(pos6144); coor6144]';
    
    exec(conn, ['create table MS_pos2coor6144 (pos int not null, 6144plate int not null,'...
        ' 6144row int not null, 6144col int not null)']);
    tablename = 'MS_pos2coor6144';
    colnames = {'pos','6144plate','6144row','6144col'};
    datainsert(conn,tablename,colnames,plate6144);
   
%%  STRAINS ALL

%   plate384
    strain384_3    = fetch(conn, ['select strain_id from MS_pos2strainid ',...
        'where pos between 1 and 384 order by pos asc ']);
    strain384_3 = col2grid(strain384_3.strain_id);

    strain384_5    = fetch(conn, ['select strain_id from MS_pos2strainid ',...
        'where pos between 385 and 384*2 order by pos asc ']);
    strain384_5    = col2grid(strain384_5.strain_id);
    
    strain384_22    = fetch(conn, ['select strain_id from MS_pos2strainid ',...
        'where pos between 384*2+1 and 384*3 order by pos asc ']);
    strain384_22   = col2grid(strain384_22.strain_id);

    strain384_c    = fetch(conn, ['select strain_id from MS_pos2strainid ',...
        'where pos between 384*3+1 and 384*4 order by pos asc ']);
    strain384_c    = col2grid(strain384_c.strain_id);

%   plate1536
    strain1536_1 = plategen(strain384_c,strain384_3,strain384_5,strain384_22);
    strain1536_2 = plategen(strain384_22,strain384_c,strain384_3,strain384_5);
    strain1536_3 = plategen(strain384_5,strain384_22,strain384_c,strain384_3);
    strain1536_4 = plategen(strain384_3,strain384_5,strain384_22,strain384_c);
    
    strain1536   = [plate1536(:,1)';[grid2row(strain1536_1), grid2row(strain1536_2),...
        grid2row(strain1536_3), grid2row(strain1536_4)]]';    
    
    tablename = 'MS_pos2strainid';
    colnames = {'pos','strain_id'};
    datainsert(conn,tablename,colnames,strain1536);    
    
%   plate6144
    strain6144 = plategen(strain1536_1,strain1536_2,strain1536_3,strain1536_4);
    
    strain6144   = [plate6144(:,1)'; grid2row(strain6144)]';
    
    tablename = 'MS_pos2strainid';
    colnames = {'pos','strain_id'};
    datainsert(conn,tablename,colnames,strain6144);
    
%%
    conn(close);


