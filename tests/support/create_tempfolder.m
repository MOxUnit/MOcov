function folderpath = create_tempfolder(foldername)
    % Create a folder inside the default temporary director
    % and returns it path.
    %
    % If the folder already exists, do nothing...

    folderpath = ensure_path_in_tempdir(foldername);

    [unused, unused, unused] = mkdir(folderpath);
    % Avoid existing folder warnings by receiving all the 3 outputs of mkdir
end
