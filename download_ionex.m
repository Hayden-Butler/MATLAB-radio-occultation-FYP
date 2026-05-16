function IONEX_data = download_ionex(date_string)

token = '';%use GNSS token
 
dt  = datetime(date_string, 'InputFormat', 'dd-MM-yyyy', 'TimeZone', 'UTC');
doy = day(dt, 'dayofyear');
yr  = year(dt);

filenames_to_try = {
    sprintf('IGS0OPSFIN_%04d%03d0000_01D_02H_GIM.INX.gz', yr, doy),
    sprintf('IGS0OPSRAP_%04d%03d0000_01D_02H_GIM.INX.gz', yr, doy),
    sprintf('JPL0OPSFIN_%04d%03d0000_01D_02H_GIM.INX.gz', yr, doy),
    sprintf('JPL0OPSRAP_%04d%03d0000_01D_02H_GIM.INX.gz', yr, doy),
};

base_url = sprintf('https://cddis.nasa.gov/archive/gnss/products/ionex/%04d/%03d/', yr, doy);
local_gz   = fullfile(pwd, 'ionex_temp.gz');
local_file = fullfile(pwd, 'ionex_temp.INX');

opts = weboptions(...
    'HeaderFields', {'Authorization', ['Bearer ', token]}, ...
    'Timeout', 60, ...
    'CertificateFilename', '');

success = false;
for k = 1:length(filenames_to_try)
    url = [base_url, filenames_to_try{k}];
    fprintf('Trying: %s\n', url);
    try
        websave(local_gz, url, opts);
        info = dir(local_gz);
        if isempty(info) || info.bytes == 0
            fprintf('  -> Empty\n');
            continue
        end
        fprintf('Downloaded: %s (%.1f KB)\n', filenames_to_try{k}, info.bytes/1024);
        success = true;
        break
    catch e
        fprintf('  -> Failed: %s\n', e.message);
    end
end

if ~success
    error('Could not download IONEX for %s', date_string);
end

fprintf('Decompressing...\n');
try
    out = gunzip(local_gz, pwd);
    movefile(out{1}, local_file, 'f');
catch e
    error('Decompression failed: %s', e.message);
end

ionex = parse_ionex(local_file, dt);
fprintf('Parsed: %d TEC maps, %d lats x %d lons\n', ...
    length(ionex.maps), length(ionex.lats), length(ionex.lons));
IONEX_data = ionex_to_cosmic_format(ionex);
IONEX_data = IONEX_data(:);
delete(local_gz);
delete(local_file);
end


% =========================================================================
function ionex = parse_ionex(filepath, dt)
% Local function — must stay in same file as download_ionex

fid = fopen(filepath, 'r');
if fid == -1, error('Could not open: %s', filepath); end

ionex.lats  = [];
ionex.lons  = [];
ionex.times = NaT(0, 1);
ionex.times.TimeZone = 'UTC';
ionex.maps  = {};

exponent    = -1;
in_header   = true;
in_map      = false;
current_map = [];
current_row = 0;
col_fill    = 0;
map_time    = NaT;

while ~feof(fid)
    line = fgetl(fid);
    if ~ischar(line), break; end

    if in_header
        if contains(line, 'END OF HEADER')
            in_header = false;
        elseif contains(line, 'EXPONENT')
            exponent = str2double(strtrim(line(1:6)));
        elseif contains(line, 'LAT1 / LAT2 / DLAT')
            v = sscanf(line(1:30), '%f %f %f');
            ionex.lats = v(1) : v(3) : v(2);
        elseif contains(line, 'LON1 / LON2 / DLON')
            v = sscanf(line(1:30), '%f %f %f');
            ionex.lons = v(1) : v(3) : v(2);
        elseif contains(line, 'HGT1 / HGT2 / DHGT')
            ionex.height = str2double(line(3:8));
        end
        continue
    end

    if contains(line, 'START OF TEC MAP')
        in_map      = true;
        current_map = NaN(length(ionex.lats), length(ionex.lons));
        current_row = 0;
        col_fill    = 0;

    elseif contains(line, 'END OF TEC MAP') && in_map
        ionex.maps{end+1}  = current_map * 10^exponent;
        ionex.times(end+1) = map_time;
        in_map = false;

    elseif contains(line, 'EPOCH OF CURRENT MAP') && in_map
        v        = sscanf(line(1:36), '%d %d %d %d %d %d');
        map_time = datetime(v(1),v(2),v(3),v(4),v(5),v(6), 'TimeZone','UTC');

    elseif contains(line, 'LAT/LON1/LON2/DLON/H') && in_map
        current_row = current_row + 1;
        col_fill    = 0;

    elseif in_map && current_row > 0
        vals = sscanf(line, '%f')';
        if ~isempty(vals)
            range    = col_fill+1 : col_fill+length(vals);
            range    = range(range <= length(ionex.lons));
            current_map(current_row, range) = vals(1:length(range));
            col_fill = col_fill + length(vals);
        end
    end
end
fclose(fid);

% Grids
[LON_grid, LAT_grid] = meshgrid(ionex.lons, ionex.lats);
ionex.lat_grid = LAT_grid;
ionex.lon_grid = LON_grid;

% TEC → NmF2 (slab thickness model, units el/cm^3)
slab_m = 230e3;
ionex.nmf2_maps = cellfun(@(t) (t * 1e16) / slab_m / 1e6, ...
    ionex.maps, 'UniformOutput', false);

% hmF2 climatological estimate
ionex.hmf2_map = 300 + 50 * cosd(LAT_grid);

end

function IONEX_data = ionex_to_cosmic_format(ionex)

IONEX_data = cell(0,1);
entry_count = 0;

for t = 1:length(ionex.times)
    map_time = ionex.times(t);
    tec_map  = ionex.maps{t};
    nmf2_map = ionex.nmf2_maps{t};

    for i = 1:length(ionex.lats)
        for j = 1:length(ionex.lons)

            tec  = tec_map(i,j);
            nmf2 = nmf2_map(i,j);
            if isnan(tec) || isnan(nmf2), continue; end

            entry_count = entry_count + 1;
            s = struct();

            % Vector fields (length-1 vectors to match COSMIC profile format)
            s.GEO_lat   = ionex.lats(i);       % [1x1 double]
            s.GEO_lon   = ionex.lons(j);
            s.MSL_alt   = ionex.height;
            s.TEC_cal   = tec;
            s.ELEC_dens = nmf2 * 1e6;

            % Scalar attribute fields (matching COSMIC attlist)
            s.month     = month(map_time);
            s.day       = day(map_time);
            s.hour      = hour(map_time);
            s.minute    = minute(map_time);
            s.second    = second(map_time);
            s.reference_sat_id = NaN;
            s.edmaxtime = map_time;
            s.edmaxalt  = ionex.hmf2_map(i,j);
            s.edmaxlat  = ionex.lats(i);
            s.edmaxlon  = ionex.lons(j);
            s.edmax     = nmf2;

            % Source fields
            s.LEO_ID       = NaN;
            s.mission_name = 'IONEX_IGS';

            IONEX_data{entry_count,1} = s;
        end
    end
end

fprintf('Converted %d IONEX grid points to COSMIC-format structs\n', entry_count);
end