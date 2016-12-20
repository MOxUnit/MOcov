function filepath = create_tempfile(filename, contents)
    % Creates a temporary file with the specified content.

    filepath = ensure_path_in_tempdir(filename);

    % Make sure eventual folder exists
    tempfolder = fileparts(filepath);
    create_tempfolder(tempfolder);

    fid = fopen(filepath, 'w');
    fprintf(fid, contents);
    fclose(fid);
end
