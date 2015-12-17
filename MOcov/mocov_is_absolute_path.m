function tf=mocov_is_absolute_path(fn)
    n=numel(fn);
    if ispc()
        tf=n>=2 && fn(2)==':';
    else
        tf=n>=1 && (fn(1)=='/' || fn(1)=='~');
    end