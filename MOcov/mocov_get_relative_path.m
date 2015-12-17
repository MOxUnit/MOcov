function rel_fn=mocov_get_relative_path(root_fn, fn)
% get the path of fn relative to root_fn
    abs_root_fn=mocov_get_absolute_path(root_fn);
    abs_fn=mocov_get_absolute_path(fn);

    n=numel(abs_root_fn);
    if ~strncmp(abs_root_fn,abs_fn,n)
        error('Absolute filename ''%s'' must start with ''%s''',...
                abs_fn, abs_root_fn);
    end

    if numel(abs_fn)==n
        rel_fn='';
        return;
    end

    if abs_fn(n+1)~=filesep()
        error('Expected path separator at position %d in ''%s''',...
                    n+1, abs_fn);
    end

    rel_fn=abs_fn((n+2):end);
