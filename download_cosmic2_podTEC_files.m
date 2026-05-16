function download_cosmic2_podTEC_files(year, day)
    % Define the base URL
    base_url = 'https://data.cosmic.ucar.edu/gnss-ro/cosmic2/nrt/level1b/';%'https://data.cosmic.ucar.edu/gnss-ro/cosmic2/provisional/spaceWeather/level2/';
    
    % Define the folder name based on the year
    folder_name = [num2str(year) '_RO_COSMIC_2_data_podtec'];
    
    % Create the folder if it does not exist
    if ~exist(folder_name, 'dir')
        mkdir(folder_name);
    end
    

    % Format the day to be a three-digit string
    day_str = sprintf('%03d', day);
    
    % Construct the full URL for the tar.gz file
    url = [base_url num2str(year) '/' day_str '/podTc2_nrt_' num2str(year) '_' day_str '.tar.gz'];
    
    % Define the local filename to save the downloaded file
    filename = fullfile(folder_name, ['podTc2_nrt_' num2str(year) '_' day_str '.tar.gz']);
    
    % Use  to download the file
    try
        cmd = sprintf('curl -s -o "%s" "%s"', filename, url);
        [status, ~] = system(cmd, '-echo');
    catch ME
        fprintf('Failed to download file from: %s\n error %s', url, ME.message);
    end
end