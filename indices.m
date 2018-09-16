%%  Sau MATLAB Colony Analyzer Toolkit
%
%%  indices.m
%   
%   Author: Saurin Parikh, September, 2017
%   dr.saurin.parikh@gmail.com
%   
%%

    function output = indices(density)

        if density == 6144
            r = 64;
            c = 96;
        elseif density == 1536
            r = 32;
            c = 48;
        elseif density == 384
            r = 16;
            c = 24;
        else
            r = 8;
            c = 12;
        end

        i = 1;
        rows = [];
        aaa = linspace(1,r,r);

        while i <= c
            rows = [rows, aaa];
            i = i + 1;
        end

        i = 1;
        cols = [];
        bbb = ones(1,r);

        while i <= c
            cols = [cols, bbb*i];
            i = i + 1;
        end

    output = [rows; cols];

