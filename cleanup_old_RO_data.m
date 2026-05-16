function cleanup_old_RO_data()
    folders = dir('*_RO_*');
    folders = folders([folders.isdir]);

    if isempty(folders)
        fprintf('No old _RO_ folders found.\n');
        return
    end

    for k = 1:length(folders)
        folderPath = fullfile(folders(k).folder, folders(k).name);
        fprintf('Found folder: %s\n', folderPath);

        % Ask for user confirmation
        answer = input('Do you want to delete this folder? Y/N [N]: ', 's');
        if isempty(answer)
            answer = 'N';
        end

        if strcmpi(answer, 'Y')
            fprintf('Deleting folder: %s\n', folderPath);
            rmdir(folderPath, 's');
        else
            fprintf('Skipped folder: %s\n', folderPath);
        end
    end

    fprintf('Cleanup complete.\n');
end