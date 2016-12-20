function newpath = ensure_path_in_tempdir(oldpath)
    % Check if path start with the tempdir.
    % If not, prepend the tempdir to path.
    %
    % Returns a path that starts with tempdir.

    len = length(tempdir);
    if length(oldpath) >= len && strcmp(oldpath(1:len), tempdir)
        % Just ignore if oldpath already include the tempdir path
        newpath = oldpath;
    else
        newpath = fullfile(tempdir, oldpath);
    end
end
