function obj=rewrite_mfiles(obj, temp_dir)
    obj.temp_dir=temp_dir;

    mfiles=obj.mfiles;
    if ~iscell(mfiles)
        error('No mfiles - did you call ''prepare''?');
    end

    root_dir=obj.root_dir;

    n=numel(mfiles);
    for k=1:n
        mfile=mfiles{k};

        fn=get_filename(mfile);

        rel_fn=mocov_get_relative_path(root_dir, fn);
        tmp_fn=fullfile(temp_dir, rel_fn);

        decorator=@(line_number) sprintf(['mocov_line_covered'...
                                            '(''' rel_fn ''',%d);'],...
                                            line_number);
        write_lines_with_prefix(mfile, tmp_fn, decorator);
        notify(obj.monitor,'.',sprintf('Rewrote %s', rel_fn));
    end

