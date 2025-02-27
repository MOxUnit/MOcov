function test_suite = test_mocov_get_relative_path()
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_mocov_get_relative_path_basics()
    fs = filesep();
    sps = @(str)strrep(str, '/', fs);
    aeq = @(a, varargin)assertEqual(sps(a), sps(mocov_get_relative_path(varargin{:})));

    aeq('foo', '', 'foo');
    aeq('foo', 'bar', 'bar/foo');
    aeq('foo', 'bar//', 'bar/foo');
    aeq('foo', 'bar//baz/', 'bar/baz/foo');
    aeq('foo', '/bar//', '/bar/foo');
    aeq('foo', '/bar/baz/', '/bar/baz/foo');
    aeq('baz/foo', '/bar/', '/bar/baz/foo');
    aeq('baz/foo', 'bar/', 'bar/baz/foo');
    aeq('', 'bar/baz', 'bar/baz');
    aeq('', '/bar/baz', '/bar/baz');

function test_mocov_get_relative_path_exceptions()
    aet = @(varargin)assertExceptionThrown(@() ...
                                           mocov_get_relative_path(varargin{:}), '');

    aet('bar/a', 'foo');
    aet('bar', 'foo');
    aet('bar/baz', 'baz/bar/foo');
    aet('baz/bar/ba', 'baz/bar/baaa');
