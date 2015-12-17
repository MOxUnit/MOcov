function obj=MOcovMFileCollection(root_dir, method, monitor)
% instantiate MOcovMFileCollection
%
% obj=MOcovMFileCollection(root_dir, method, monitor)
%
% Inputs:
%   root_dir                root directory containing m-files to be
%                           covered.
%   method                  Coverage method, one of:
%                           - 'file'    rewrite m-files after adding
%                                       statements that record which lines
%                                       are covered
%                           - 'profile' use Matlab profiler
%                           default: 'file'
%   monitor                 optional MOcovProgressMonitor instance
%
% See also: mocov

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

