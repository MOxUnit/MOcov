function obj=prepare(obj)
    monitor=obj.monitor;

    fns=mocov_find_files(obj.root_dir,'*.m',monitor);
    n=numel(fns);

    mfiles=cell(n,1);
    for k=1:n
        fn=fns{k};
        mfiles{k}=MOcovMFile(fn);
    end

    obj.mfiles=mfiles;

    if ~ischar(obj.method)
        error('method must be char, found %s', class(obj.method));
    end

    switch obj.method
        case 'profile'
            profile on

        case 'file'
            % store original path
            obj.orig_path=path();
            notify(monitor,'Preserving original path');

            temp_dir=tempname();
            obj=rewrite_mfiles(obj,temp_dir);

            addpath(genpath(obj.temp_dir));
            notify(monitor,'',sprintf('Path is: %s\n', path()));
    end