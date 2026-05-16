function IONEX_binned = bin_ionex_data(IONEX_data)
% Bins IONEX_data cell array into larger grid cells by averaging
% Loops through all 2-hour windows and bins by both time and location

% Extract reference day for edge case handling
ref_day = day(IONEX_data{1}.edmaxtime);
lat_bin_size = 10;
lon_bin_size = 10;

% Convert all times to fractional hours, fixing day boundary edge case
get_hour = @(s) hour(s.edmaxtime) + ...
    24 * (day(s.edmaxtime) > ref_day) + ...
    minute(s.edmaxtime) / 60;

all_hours = cellfun(get_hour, IONEX_data);
lats      = cellfun(@(s) s.GEO_lat, IONEX_data);
lons      = cellfun(@(s) s.GEO_lon, IONEX_data);
tec       = cellfun(@(s) s.TEC_cal, IONEX_data);
nmf2      = cellfun(@(s) s.edmax,   IONEX_data);

% Define bin edges
lat_edges = -90  : lat_bin_size : 90;
lon_edges = -180 : lon_bin_size : 180;

IONEX_binned = {};
entry_count  = 0;

for target_hour = 0:2:22

    % Filter to only points within this 2-hour window
    time_mask     = all_hours >= target_hour & all_hours < (target_hour + 2);
    if ~any(time_mask), continue; end

    IONEX_at_time = IONEX_data(time_mask);
    lats_t        = lats(time_mask);
    lons_t        = lons(time_mask);
    tec_t         = tec(time_mask);
    nmf2_t        = nmf2(time_mask);
    time          = IONEX_at_time{1}.edmaxtime;

    fprintf('Window %02d:00-%02d:00: %d points\n', target_hour, target_hour+2, sum(time_mask));

    for i = 1:length(lat_edges)-1
        for j = 1:length(lon_edges)-1

            in_bin = lats_t >= lat_edges(i) & lats_t < lat_edges(i+1) & ...
                     lons_t >= lon_edges(j) & lons_t < lon_edges(j+1);

            if ~any(in_bin), continue; end

            entry_count = entry_count + 1;
            s = struct();

            s.GEO_lat          = mean(lats_t(in_bin));
            s.GEO_lon          = mean(lons_t(in_bin));
            s.MSL_alt          = IONEX_at_time{1}.MSL_alt;
            s.TEC_cal          = mean(tec_t(in_bin));
            s.ELEC_dens        = mean(cellfun(@(s) s.ELEC_dens, IONEX_at_time(in_bin)));
            s.month            = month(time);
            s.day              = day(time);
            s.hour             = target_hour;
            s.minute           = 0;
            s.second           = 0;
            s.reference_sat_id = NaN;
            s.edmaxtime        = time;
            s.edmaxalt         = mean(cellfun(@(s) s.edmaxalt, IONEX_at_time(in_bin)));
            s.edmaxlat         = mean(lats_t(in_bin));
            s.edmaxlon         = mean(lons_t(in_bin));
            s.edmax            = mean(nmf2_t(in_bin));
            s.LEO_ID           = NaN;
            s.mission_name     = 'IONEX_IGS';

            IONEX_binned{entry_count, 1} = s;
        end
    end
end

fprintf('Total: binned into %d cells (%dx%d deg, 2hr windows)\n', ...
    entry_count, lat_bin_size, lon_bin_size);
end