function obj=MOcovMFileCollection(root_dir, method, monitor)
    if nargin<3 || isempty(monitor)
        monitor=MOcovProgressMonitor();
    end

    if nargin<2 || isempty(method);
        method='file';
    end


    props=struct();
    props.root_dir=root_dir;
    props.monitor=monitor;
    props.mfiles=[];
    props.orig_path=[];
    props.temp_dir=[];
    props.method=method;
    obj=class(props,'MOcovMFileCollection');

