function download_cosmic1_files(year, day)
    % Define the base URL
    base_url = 'https://data.cosmic.ucar.edu/gnss-ro/cosmic1/repro2021/level2/';%'https://data.cosmic.ucar.edu/gnss-ro/cosmic2/provisional/spaceWeather/level2/';
    
    % Define the folder name based on the year
    folder_name = [num2str(year) '_RO_TEST_COSMIC_1_data'];
    
    % Create the folder if it does not exist
    if ~exist(folder_name, 'dir')
        mkdir(folder_name);
    end
    

    % Format the day to be a three-digit string
    day_str = sprintf('%03d', day);
    
    % Construct the full URL for the tar.gz file
    url = [base_url num2str(year) '/' day_str '/ionPrf_repro2021_' num2str(year) '_' day_str '.tar.gz'];
    
    % Define the local filename to save the downloaded file
    filename = fullfile(folder_name, ['ionPrf_repro2021_' num2str(year) '_' day_str '.tar.gz']);
    
    % Use websave to download the file
    try
        outfile = websave(filename, url);
        fprintf('File saved to: %s\n', outfile);
    catch
        fprintf('Failed to download file from: %s\n', url);
    end
end