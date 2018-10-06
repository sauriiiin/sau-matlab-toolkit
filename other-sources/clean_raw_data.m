

function [data_out, data_out_avg] = clean_raw_data(data_in, n_plate, density, threshold)
    
    if nargin < 4
        threshold = 30;
    end
    
    data_out = data_in;
    
    for pp = 1 : n_plate
        plate_data = data_out((n_plate-1)*density+1:n_plate*density, :);
        
        temp1 = plate_data(:, 1) - plate_data(:, 2);
        data_out(temp1 > threshold, 1) = NaN;
        data_out(temp1 < threshold * -1, 2) = NaN;
        
        temp2 = plate_data(:, 1) - plate_data(:, 3);
        data_out(temp2 > threshold, 1) = NaN;
        data_out(temp2 < threshold * -1, 3) = NaN;
        
        temp3 = plate_data(:, 2) - plate_data(:, 3);
        data_out(temp3 > threshold, 2) = NaN;
        data_out(temp3 < threshold * -1, 3) = NaN;
    end
    data_out_avg = nanmean(data_out, 2);
end