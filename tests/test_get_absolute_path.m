function test_suite = test_get_absolute_path
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_get_absolute_path_basics()
    % Modify test to support windows
    if ispc()
        fs = filesep();
        sps = @(str)strrep(str, '/', fs);

        % Prepend tests with 'c:' and flip to windows filesep
        aeq = @(a, b)assertEqual(mocov_get_absolute_path( ...
                                                         ['c:', sps(a)]), ...
                                 ['c:', sps(b)]);
    else
        aeq = @(a, b)assertEqual(mocov_get_absolute_path(a), b);
    end

    % Absolute path checks starting at a drive root
    aeq('/', '/');
    aeq('/foo/../', '/');
    aeq('/foo/..//', '/');
    aeq('/foo/..', '/');
    aeq('/foo/../.', '/');
    aeq('/foo/.././', '/');

    % Present working directory
    orig_pwd = pwd();
    cleaner = onCleanup(@()cd(orig_pwd));
    p = fileparts(mfilename('fullpath'));
    cd(p);
    assertEqual(mocov_get_absolute_path(''), p);
