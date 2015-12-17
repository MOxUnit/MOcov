function mocov(varargin)
    opt=parse_inputs(varargin{:});

    monitor=MOcovProgressMonitor(opt.verbose);

    mfile_collection=MOcovMFileCollection(opt.mfile_dir,...
                                                opt.method,...
                                                monitor);

    mfile_collection=prepare(mfile_collection);
    cleaner_collection=onCleanup(@()cleanup(mfile_collection));

    line_covered_state=mocov_line_covered();
    cleaner_covered=onCleanup(@()mocov_line_covered(...
                                            line_covered_state));

    % reset lines covered to empty
    mocov_line_covered([]);

    % evaluate expression
    evaluate_expression(opt.expression);

    % see which lines were executed
    mfile_collection=set_lines_executed(mfile_collection);

    if ~isempty(opt.html_dir)
        html_dir=mocov_get_absolute_path(opt.html_dir);

        % write HTML
        write_html(mfile_collection, html_dir);
    end

    if ~isempty(opt.xml_file)
        xml_file=mocov_get_absolute_path(opt.xml_file);

        % write XML
        write_xml(mfile_collection, xml_file);
    end


function evaluate_expression(the_expression___)
    if isa(the_expression___,'function_handle')
        the_expression___();
    elseif ischar(the_expression___)
        eval(the_expression___);
    else
        error('unable to evaluate expression of class %s',...
                            class(the_expression___));
    end


function opt=parse_inputs(varargin)
    % process input options

    defaults=struct();
    defaults.mfile_dir=pwd();
    defaults.html_dir=[];
    defaults.xml_file=[];
    defaults.verbose=2;
    defaults.method='file';
    defaults.expression=[];

    opt=defaults;

    n=numel(varargin);
    k=0;
    while k<n
        k=k+1;
        arg=varargin{k};

        if ischar(arg)
            switch arg
                case '-html'
                    k=k+1;
                    opt.html_dir=varargin{k};

                case '-xml'
                    k=k+1;
                    opt.xml_file=varargin{k};

                case '-c'
                    k=k+1;
                    opt.mfile_dir=varargin{k};

                case '-v'
                    opt.verbose=opt.verbose+1;

                case '-q'
                    opt.verbose=opt.verbose-1;

                case '-e'
                    k=k+1;
                    opt.expression=varargin{k};

                case '-m'
                    k=k+1;
                    opt.method=varargin{k};

                otherwise
                    error('illegal option ''%s''', arg)
            end
        elseif isa(arg,'function_handle')
            opt.expression=arg;
        else
            error('Input argument %d not understood', k);
        end
    end

    check_inputs(opt);


function check_inputs(opt)
    if ~isdir(opt.mfile_dir)
        error('input dir ''%s'' does not exist', opt.mfile_dir);
    end

    if isempty(opt.expression)
        error('expression option ''-e'' not supplied');
    end