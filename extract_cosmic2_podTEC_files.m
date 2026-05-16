function extract_cosmic2_podTEC_files(year)
    % Define the folder name based on the year
    folder_name = [num2str(year) '_RO_COSMIC_2_data_podtec'];
    
    % Check if the folder exists
    if ~exist(folder_name, 'dir')
        error('Folder %s does not exist.', folder_name);
    end
    
    % Get a list of all .tar.gz files in the folder
    gz_files = dir(fullfile(folder_name, '*.tar.gz'));
    
    % Loop through each .tar.gz file
    for i = 1:length(gz_files)
        % Construct the full path to the .tar.gz file
        gz_file = fullfile(folder_name, gz_files(i).name);
        
        % Define the name of the tar file after ungzipping
        tar_file = fullfile(folder_name, gz_files(i).name(1:end-3)); % remove the .gz extension
        
        % Unzip the .gz file to get the .tar file
        try
            gunzip(gz_file, folder_name);
            fprintf('Unzipped %s\n', gz_file);
        catch
            fprintf('Failed to unzip %s\n', gz_file);
            continue;
        end
        
        % Untar the .tar file
        try
            untar(tar_file, folder_name);
            fprintf('Extracted %s\n', tar_file);
            
            % Optionally, delete the .tar file after extraction
            delete(tar_file);
        catch
            fprintf('Failed to extract %s\n', tar_file);
        end
        
        % Optionally, delete the .tar.gz file after extraction
        delete(gz_file);
    end
end
