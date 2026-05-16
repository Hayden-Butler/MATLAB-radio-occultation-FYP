function download_cosmic2_files(year, day)
    % Define the base URL
    base_url = 'https://data.cosmic.ucar.edu/gnss-ro/cosmic2/provisional/spaceWeather/level2/';%'https://data.cosmic.ucar.edu/gnss-ro/cosmic2/provisional/spaceWeather/level2/';
    
    % Define the folder name based on the year
    folder_name = [num2str(year) '_RO_COSMIC_2_data'];
    
    % Create the folder if it does not exist
    if ~exist(folder_name, 'dir')
        mkdir(folder_name);
    end
    

    % Format the day to be a three-digit string
    day_str = sprintf('%03d', day);
    
    % Construct the full URL for the tar.gz file
    url = [base_url num2str(year) '/' day_str '/ionPrf_prov1_' num2str(year) '_' day_str '.tar.gz'];
    
    % Define the local filename to save the downloaded file
    filename = fullfile(folder_name, ['ionPrf_prov1_' num2str(year) '_' day_str '.tar.gz']);
    
    % Use websave to download the file
    try
        outfile = websave(filename, url);
        fprintf('File saved to: %s\n', outfile);
    catch
        fprintf('Failed to download file from: %s\n', url);
    end
end
 %https://data.cosmic.ucar.edu/gnss-ro/cosmic2/provisional/spaceWeather/level2/2020/001/ionPrf_prov1_2020_001.tar.gz