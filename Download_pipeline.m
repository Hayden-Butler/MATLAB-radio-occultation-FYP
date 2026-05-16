%% Download_pipeline.m
% Master pipeline for COSMIC processing
% Dependencies: Requires Paralell Computing Toolbox

clear; clc; clear day; clear year;
%% Parameters

date_string = '20-01-2026'; %dd-mm-yyyy
mission_name = 'COSMIC2podTEC'; %ground/COSMIC 1/COSMIC 2/COSMIC 2 podTEC

fprintf('Starting COSMIC pipeline for %s, mission %s \n', date_string, mission_name);

%% Cleanup old files
fprintf('Cleaning up old RO data')
cleanup_old_RO_data
%% Download data
%find right day
dt = datetime(date_string, 'InputFormat', 'dd-MM-yyyy', 'Format', 'dd/MM/uuuu');
d = day(dt, 'dayofyear');
day = d;
yr = year(dt);
year = yr;

fprintf('Downloading data...\n');
mission_name = strrep(mission_name,' ','');
switch mission_name
    case 'COSMIC1'
        try
            download_cosmic1_files(year, day);
            fprintf('Data downloaded\n');
        catch ME
            error("Download failed: %s", ME.message)
        end
    case 'COSMIC2'
        try
            download_cosmic2_files(year, day);
            fprintf('Data downloaded\n');
        catch ME
            error("Download failed: %s", ME.message)
        end
    case 'ground'
        try
            IONEX_data = download_ionex(date_string);
            fprintf('Data downloaded\n');
        catch ME
           error("Download failed: %s", ME.message)
        end
    case 'COSMIC2podTEC'
        try
            download_cosmic2_podTEC_files(year, day);
            fprintf('Data downloaded\n');
        catch ME
            error("Download failed: %s", ME.message)
        end
    otherwise
        error('Unknown mission: %s', mission_name);
end
%% Extract data
fprintf('Extracting files...\n');
switch mission_name
    case 'COSMIC1'
        try
            extract_cosmic1_files(year);
            fprintf('Data extracted\n');
        catch ME
            error("Extraction failed: %s", ME.message)
        end
    case 'COSMIC2'
        try
            extract_cosmic2_files(year);
            fprintf('Data extracted\n');
        catch ME
            error("Extraction failed: %s", ME.message)
        end
    case 'ground'
        fprintf('Ground data — no extraction needed\n');
    case 'COSMIC2podTEC'
        try
            extract_cosmic2_podTEC_files(year);
            fprintf('Data extracted\n');
        catch ME
            error("Extraction failed: %s", ME.message)
        end
    otherwise
        error('Unknown mission: %s', mission_name);
end

%% Process data
if isempty(gcp('nocreate'))
    parpool('local');
end
fprintf('Processing data...\n');
switch mission_name
    case {'COSMIC1', 'COSMIC2', 'COSMIC2podTEC'}
        COSMIC_data = get_data(year);
    case 'ground'
        IONEX_data = bin_ionex_data(IONEX_data);
        COSMIC_data = IONEX_data;
end
fprintf('\n')
fprintf('Processing complete\n')

clear yr; clear d; clear dt; clear date_string; clear IONEX_data
