function [mfile,idx]=get_mfile(obj, fn)
    root_dir=obj.root_dir;
    abs_fn=mocov_get_absolute_path(fullfile(root_dir,fn));

    mfiles=obj.mfiles;
    n=numel(mfiles);
    for k=1:n
        mfile=mfiles{k};
        mfile_fn=get_filename(mfile);
        if strcmp(mfile_fn, abs_fn)
            idx=k;
            return;
        end
    end

    error('Not found: %s', fn);
