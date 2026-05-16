function COSMIC_data = ionex_to_cosmic_format(ionex)
% Converts IONEX struct into cell array of structs matching COSMIC_data format

IONEX_data = {};
entry_count = 0;

for t = 1:length(ionex.times)
    map_time = ionex.times(t);
    tec_map  = ionex.maps{t};
    nmf2_map = ionex.nmf2_maps{t};

    for i = 1:length(ionex.lats)
        for j = 1:length(ionex.lons)

            tec  = tec_map(i,j);
            nmf2 = nmf2_map(i,j);

            % Skip missing values
            if isnan(tec) || isnan(nmf2), continue; end

            entry_count = entry_count + 1;
            s = struct();

            s.edmaxlat  = ionex.lats(i);
            s.edmaxlon  = ionex.lons(j);
            s.edmax     = nmf2;           
            s.edmaxalt  = ionex.hmf2_map(i,j);
            s.TEC       = tec;       
            s.edmaxtime = map_time;
            s.source    = 'IONEX_IGS';    

            IONEX_data{entry_count} = s;
        end
    end
end

fprintf('Converted %d IONEX grid points to COSMIC-format structs\n', entry_count);
end