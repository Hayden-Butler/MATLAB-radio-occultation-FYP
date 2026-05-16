untar("ionPrf_prov1_2024_130.tar.gz","RO_COSMIC_2_data\")
untar("ionPrf_prov1_2024_131.tar.gz","RO_COSMIC_2_data\")
untar("ionPrf_prov1_2024_132.tar.gz","RO_COSMIC_2_data\")

% Define the folder path
folder_path_24 = 'D:\MayStorm\COSMIC_132';

% Get a list of all .nc files in the directory that end with .0001_nc
nc_files = dir(fullfile(folder_path_24, '*0001_nc'));

% Loop through each file
for file_idx = 1:length(nc_files)
    % Get the full path of the current file
    nc_file = fullfile(folder_path_24, nc_files(file_idx).name);

    % Display the contents of the NetCDF file (optional)
    ncdisp(nc_file);

    % Read the necessary variables from the NetCDF file
    geo_lat = ncread(nc_file, 'GEO_lat');
    geo_lon = ncread(nc_file, 'GEO_lon');
    MSL_alt = ncread(nc_file, 'MSL_alt');
    tec_cal = ncread(nc_file, 'TEC_cal');
    ELEC_dens = ncread(nc_file, 'ELEC_dens');
    month = ncreadatt(nc_file, '/','month');
    day = ncreadatt(nc_file, '/','day');
    hour = ncreadatt(nc_file, '/','hour');
    minute = ncreadatt(nc_file, '/','minute');
    second = ncreadatt(nc_file, '/','second');

    % Create time vectors
    time_month = repmat(month, size(geo_lat));
    time_day = repmat(day, size(geo_lat));
    time_hour = repmat(hour, size(geo_lat));
    time_minute = repmat(minute, size(geo_lat));
    time_seconds = repmat(second, size(geo_lat));

    % Combine the data into one matrix
    COSMIC_data = horzcat(double(time_month),double(time_day), double(time_hour), double(time_minute), ...
                          double(time_seconds), geo_lat, geo_lon, MSL_alt, ELEC_dens);
    
end
