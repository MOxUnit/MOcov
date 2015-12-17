function obj=MOcovProgressMonitor(verbosity)
    if nargin<1
        verbosity=1;
    end

    props=struct();
    props.verbosity=verbosity;
    obj=class(props,'MOcovProgressMonitor');

