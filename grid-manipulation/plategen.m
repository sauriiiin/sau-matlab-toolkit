%% Sau MATLAB Colony Analyzer Toolkit
%
%%  plategen.m
%   
%   Author: Saurin Parikh, September, 2017
%   dr.saurin.parikh@gmail.com
%   
%   Generates higher density plate using four lower density plates.
%   
%   output = plategen(topleft, topright, bottomleft, bottomright)

%%
    function output = plategen(tl, tr, bl, br)
    
        [row,col] = size(tl);
        
        if row/col ~= 2/3
            tl = col2grid(tl);
            tr = col2grid(tr);
            bl = col2grid(bl);
            br = col2grid(br);
        end
        
        [row,col] = size(tl);
        r = row * 2;
        c = col * 2;
        data = ones(r,c);

        h = [];
        hh = [];

        n = 1;
        m = 1;

        i = 1;
        ii = 1;

        while n <= r
            if rem(n,2) == 1
                h(n,:) = tl(i,:);
                i = i + 1;
                n = n + 1;
            else
                h(n,:) = bl(ii,:);
                ii = ii + 1;
                n = n + 1;
            end
        end

        n = 1;
        i = 1;
        ii = 1;

        while n <= r
            if rem(n,2) == 1
                hh(n,:) = tr(i,:);
                i = i + 1;
                n = n + 1;
            else
                hh(n,:) = br(ii,:);
                ii = ii + 1;
                n = n + 1;
            end
        end

        i = 1;
        ii = 1;

        while m <= c
            if rem(m,2) == 1
                data(:,m) = data(:,m) .* h(:,i);
                i = i + 1;
                m = m + 1;
            else
                data(:,m) = data(:,m) .* hh(:,ii);
                ii = ii + 1;
                m = m + 1;
            end
        end

    output = data;