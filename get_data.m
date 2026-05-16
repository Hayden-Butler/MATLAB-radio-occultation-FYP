function COSMIC_data = get_data(year)
    %% Main loop: Process data from COSMIC satelites into a useable form
    % Outputs COSMIC_data cell with each cell containing structures of the
    % variables/attributes
    format short g

    % Find folder and files used
    cosmic_1_folder_name = [num2str(year) '_RO_TEST_COSMIC_1_data'];
    cosmic_2_folder_name = [num2str(year), '_RO_COSMIC_2_data'];
    cosmic_2_podTEC_folder_name = [num2str(year) '_RO_COSMIC_2_data_podtec'];

    % Identify which mission was used
    if exist(cosmic_1_folder_name, 'dir')
        folder_name = cosmic_1_folder_name;
        mission_name = 'COSMIC_1';
    elseif exist(cosmic_2_folder_name, 'dir')
        folder_name = cosmic_2_folder_name;
        mission_name = 'COSMIC_2';
    elseif exist(cosmic_2_podTEC_folder_name, 'dir')
        folder_name = cosmic_2_podTEC_folder_name;
        mission_name = 'COSMIC_2_podTEC';
    else
        error('Folder does not exist.');
    end
    fprintf('mission name = %s', mission_name)

    nc_files = dir(fullfile(folder_name, '*_nc'));
    nFiles = length(nc_files);
    COSMIC_data = cell(nFiles,1);

    % Create lists of data to be extracted
    switch mission_name
        case {'COSMIC_1','COSMIC_2'}
            varlist = {'GEO_lat','GEO_lon','MSL_alt','TEC_cal','ELEC_dens'};
            attlist = {'month','day','hour','minute','second','reference_sat_id','edmaxtime','edmaxalt','edmaxlat','edmaxlon','edmax'};
        case 'COSMIC_2_podTEC'
            varlist = {'TEC', 'x_LEO', 'y_LEO', 'z_LEO', 'S4','x_GPS','y_GPS','z_GPS','elevation'};
            attlist = {'month','day','hour', 'minute', 'second', ...
               'leodcb', 'leodcb_rms', 'leodcb_flag', 'leodcb_age', ...
               'gpsdcb', 'gpsdcb_rms', 'gpsdcb_flag', 'gpsdcb_age', ...
               'leveling_err'};
    end
    
    % Loop through each file and create a struct to store in
    parfor file_idx = 1:nFiles
        nc_file  = fullfile(folder_name, nc_files(file_idx).name);
        filename = nc_files(file_idx).name;
        data     = struct();
        LEO_ID   = identify_LEO_satellite(filename, mission_name);
    
        data.mission_name = mission_name;
        data.LEO_ID       = LEO_ID;
        try
            % Data extraction
            for v = 1:length(varlist)
                varname      = varlist{v};
                data.(varname) = data_handling(nc_file, varname, mission_name);
            end
        catch ME
            warning('Skipping file %s: %s', filename, ME.message);
            COSMIC_data{file_idx} = [];
            continue;
        end
        try
            for i = 1:length(attlist)
                attname        = attlist{i};
                data.(attname) = attdata_handling(nc_file, attname, mission_name);
            end
        catch ME
            warning('Skipping file %s: %s', filename, ME.message);
            COSMIC_data{file_idx} = [];
            continue;
        end

        % ECEF conversion if needed
        if strcmp(mission_name, 'COSMIC_2_podTEC')
            wgs84 = wgs84Ellipsoid('kilometer');
            [data.GEO_lat_LEO, data.GEO_lon_LEO, data.MSL_alt_LEO] = ...
                ecef2geodetic(wgs84, data.x_LEO, data.y_LEO, data.z_LEO);
            [data.GEO_lat_GPS, data.GEO_lon_GPS, data.MSL_alt_GPS] = ...
                ecef2geodetic(wgs84, data.x_GPS, data.y_GPS, data.z_GPS);
        end
        % Apply DCB calibration if podTEC
        if strcmp(mission_name, 'COSMIC_2_podTEC')
            data = apply_dcb_calibration(data);
        end
        
        COSMIC_data{file_idx} = data;
    end
    COSMIC_data = COSMIC_data(cellfun(@isstruct, COSMIC_data));
end


function data = data_handling(nc_file, varname, mission_name)
    %Extract variable data
    data = ncread(nc_file, varname);

    % Replace missing values
    if ~strcmp(mission_name, 'COSMIC_2_podTEC')
        data(data == -999) = NaN;
    end

end

function attdata = attdata_handling(nc_file, attname, mission_name)
    %Extract attribute data
    attdata = ncreadatt(nc_file, '/',attname);
    if ~strcmp(mission_name, 'COSMIC_2_podTEC')
        attdata(attdata == -999) = NaN;
    end
end

function LEO_ID = identify_LEO_satellite(filename, mission_name)
    % Identify Leo sat from filename
    switch mission_name
        case {'COSMIC_1','COSMIC_2'}
            tokens = regexp(filename, 'ionPrf_([^.]+)\.', 'tokens');
        case 'COSMIC_2_podTEC'
            tokens = regexp(filename, 'podTc2_([^.]+)\.', 'tokens');
    end

    if isempty(tokens)
        error('Filename format not recognised: %s', filename);
    end

    mission_block = tokens{1}{1};

    switch mission_name

        case 'COSMIC_1'
            %Format: C001–C006
            LEO_ID = str2double(mission_block(2:end));

        case {'COSMIC_2', 'COSMIC_2_podTEC'}
            %Format: C2E1, C2E2,
            LEO_ID = str2double(extractAfter(mission_block,'C2E'));

        otherwise
            error('Unknown mission: %s', mission_name);

    end

end

function data = apply_dcb_calibration(data)
    % Apply LEO and GPS Differential Code Bias calibration to raw TEC
    % Calibrated TEC = TEC_raw - leodcb - gpsdcb
    % Only applies to COSMIC_2_podTEC data which carries raw TEC

    if ~strcmp(data.mission_name, 'COSMIC_2_podTEC')
        warning('DCB calibration only applicable to COSMIC_2_podTEC data. Skipping.');
        return;
    end

    % Check flags - both must be 1 for calibration to be valid
    leo_ok = isfield(data, 'leodcb_flag') && data.leodcb_flag == 1;
    gps_ok = isfield(data, 'gpsdcb_flag') && data.gpsdcb_flag == 1;

    % Check ages are not missing
    leo_age_ok = isfield(data, 'leodcb_age') && data.leodcb_age ~= -999;
    gps_age_ok = isfield(data, 'gpsdcb_age') && data.gpsdcb_age ~= -999;

    if ~(leo_ok && gps_ok && leo_age_ok && gps_age_ok)
        data.TEC_cal      = NaN(size(data.TEC));
        data.TEC_cal_unc  = NaN(size(data.TEC));
        data.dcb_cal_flag = 0;
        return;
    end

    % Apply calibration (scalar biases subtracted from full TEC profile)
    data.TEC_cal = data.TEC - data.leodcb - data.gpsdcb;

    % Propagate uncertainty: leveling_err + leodcb_rms + gpsdcb_rms in quadrature
    data.TEC_cal_unc = sqrt(data.leveling_err.^2 + data.leodcb_rms.^2 + data.gpsdcb_rms.^2);

    data.dcb_cal_flag = 1;
end





