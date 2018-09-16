%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  imageanalyzer.m

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
    
    params = { ...
        'parallel', true, ...
        'verbose', true, ...
        'grid', OffsetAutoGrid('dimensions', dimensions), ... default
        'threshold', BackgroundOffset('offset', 1.25) }; % default = 1.25
    
%%  Image Analysis

    switch questdlg('Analyze Images in this folder?',...
        'Analysis',...
        'Yes','No','Yes')
        case 'Yes'

            analyze_directory_of_images(files, params{:} );

%%  All images with no grid
        %   Those images that weren't analyzed correctly

            all = zeros(1, size(files, 1));
            for ii = 1 : size(all, 2)
                all(ii) = exist(strcat(files{ii}, '.binary'));
            end
            pos = find(all==0);

        %%  Manually fix images #1

            for ii = 1 : length(pos)
                tic;
                analyze_image( files{pos(ii)}, params{:}, ...
                    'grid', ManualGrid('dimensions', dimensions), 'threshold', BackgroundOffset('offset', 1.25));
                toc;
            end

        %%  Find Low Correlation Images

            tmp = strfind(files, '/');
            threshold = 0.99;
            %prob_img = [];
            pos = [];

            for ii = 1:3:length(files)
                if nancorrcoef(load_colony_sizes(files{ii}),...
                        load_colony_sizes(files{ii+1})) < threshold
                    %prob_img = vertcat(prob_img, files{ii}(tmp{ii}(end):end),...
                    %   files{ii+1}(tmp{ii+1}(end):end));
                    pos = [pos, ii];
                elseif nancorrcoef(load_colony_sizes(files{ii+1}),...
                        load_colony_sizes(files{ii+2})) < threshold
                    %prob_img = vertcat(prob_img, files{ii+1}(tmp{ii+1}(end):end),...
                    %    files{ii+2}(tmp{ii+2}(end):end));
                    pos = [pos, ii];
                elseif nancorrcoef(load_colony_sizes(files{ii+2}),...
                        load_colony_sizes(files{ii})) < threshold
                    %prob_img = vertcat(prob_img, files{ii+2}(tmp{ii+2}(end):end),...
                    %    files{ii}(tmp{ii}(end):end));
                    pos = [pos, ii];
                end
            end

        %%  Manually fix images #2

            for ii = 1 : size(pos,2)
                analyze_image(files{pos(ii)}, params{:}, ...
                    'grid', ManualGrid('dimensions', dimensions), 'threshold',...
                    BackgroundOffset('offset', 1.15));

                analyze_image(files{pos(ii) + 1}, params{:}, ...
                    'grid', ManualGrid('dimensions', dimensions), 'threshold',...
                    BackgroundOffset('offset', 1.15));

                analyze_image(files{pos(ii) + 2}, params{:}, ...
                    'grid', ManualGrid('dimensions', dimensions), 'threshold',...
                    BackgroundOffset('offset', 1.15));
            end
            
            
        %%  VIEW ANALYZED IMAGES
        
            pos = [];
            for ii = 1:length(files)
                view_plate_image(files{ii},'applyThreshold', true)
                switch questdlg('Was the Binary Image look fine?',...
                    'Binary Image',...
                    'Yes','No','Yes')
                    case 'No'
                        pos = [pos, ii];
                end
            end
            
    end
    