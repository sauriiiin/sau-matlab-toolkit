%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  old_raw.m

%   Author: Saurin Parikh, October 2018
%   dr.saurin.parikh@gmail.com

%   Old method of creating RAW table from image results

%%
function old_raw(files,density,p2c,hours,tablename_raw)

%%  Load data
    cs = load_colony_sizes(files);
    
%%  Mean the colony sizes from each of the images
    cs_mean = [];
    tmp = cs';
    
    for ii = 1:3:length(files)
        cs_mean = [cs_mean, mean(tmp(:,ii:ii+2),2)];
    end
       
    cs_mean = cs_mean';
%   cs_mean is number of plates x density
    
%%  Analyze Now
%   Temporarily convert all the colonies less than 10 to NaN
    the_zeros = cs_mean < 10;
    cs_nan = fil(cs_mean, the_zeros);
    
%   Spatially correct average colony size with border correction,
%       spatial correction, and mode normalization
    
    cs_corrected = [];
    cs_median = [];
     
    if density <= 1536
        for ii = 1:size(cs_nan,1)
            cs_corrected(ii,:) = apply_correction( ...
                    cs_nan(ii,:), 'dim', 2, ...
                    SpatialBorderMedian('SpatialFilter', ...
                    SpatialMedian('windowSize', 9)), ...
                    PlateMode() );
            cs_median(ii,:) = apply_correction( ...
                    cs_nan(ii,:), 'dim', 2, ...
                    'function', @(x, b) x ./ b .* nanmedian(x(:)), ...
                    SpatialBorderMedian('SpatialFilter', ...
                    SpatialMedian('windowSize', 9)), ...
                    PlateMode() );
        end
    else
        for ii = 1:size(cs_nan,1)
            cs_corrected(ii,:) = apply_correction( ...
                   cs_nan(ii,:), 'dim', 2, ...
                   InterleaveFilter(SpatialBorderMedian('SpatialFilter', ...
                   SpatialMedian('windowSize', 9))),..., 'windowShape', 'square'))), ...
                   PlateMode() );
            cs_median(ii,:) = apply_correction( ...
                   cs_nan(ii,:), 'dim', 2, ...
                   'function', @(x, b) x ./ b .* nanmedian(x(:)), ...
                   InterleaveFilter(SpatialBorderMedian('SpatialFilter', ...
                   SpatialMedian('windowSize', 9))),..., 'windowShape', 'square'))), ...
                   PlateMode() );
        end
    end

%   Converting the NaN's to zeros
    cs_corrected(the_zeros) = 0;
    cs_median(the_zeros) = 0;

    
%%  Putting everything together
    
    master = [];
    tmp = [];
    i = 1;
    for ii = 1:3:size(cs,1)
        tmp = [cs(ii,:); cs(ii+1,:); cs(ii+2,:);...
            cs_mean(i,:);cs_corrected(i,:);cs_median(i,:)];
        master = [master, tmp];
        i = i + 1;
    end
    
    master = master';
            
%%  Upload RAW Data to SQL

    connectSQL;
    
    tablename = tablename_raw;%[tablename_raw, '_OLD'];
    
    exec(conn, sprintf('drop table %s',tablename));  
    exec(conn, sprintf(['create table %s (pos int not null, hours int not null,'...
        'replicate1 int not null,'...
        'replicate2 int not null, replicate3 int not null, average double not null,'...
        'csS double not null, csM double not null)'], tablename));

    colnames = {'pos','hours'...
        'replicate1','replicate2','replicate3',...
        'average','csS','csM'};
    
    tmpdata = [];
    for ii=1:length(hours)
        tmpdata = [tmpdata; [p2c.pos, ones(length(p2c.pos),1)*hours(ii)]];
    end
    
    data = [tmpdata,master];
    tic
    datainsert(conn,tablename,colnames,data);
    toc 
end

