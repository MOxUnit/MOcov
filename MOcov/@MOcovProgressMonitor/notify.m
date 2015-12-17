function notify(obj, varargin)
    n=numel(varargin);

    verbosity=obj.verbosity;
    idx=min(n, verbosity);

    msg=varargin{idx};
    if idx>0
        if numel(msg)==1
            pat='%s';
        else
            pat='%s\n';
        end
        fprintf(pat, msg);
    end
