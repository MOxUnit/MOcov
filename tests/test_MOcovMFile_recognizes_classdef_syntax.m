function test_suite = test_MOcovMFile_recognizes_classdef_syntax
    initTestSuite;
end

function fullname = tempfile(filename, contents)
    tempfolder = fullfile(tempdir, 'mocov_fixtures');
    [~, ~, ~] = mkdir(tempfolder);
    fullname = fullfile(tempfolder, filename);
    fid = fopen(fullname, 'w');
    fprintf(fid, contents);
    fclose(fid);
end

function filename = create_classdef
    filename = tempfile('AClass.m', [ ...
        'classdef AClass < handle\n', ...
        '  properties\n', ...
        '    aProp = 1;\n', ...
        '  end\n', ...
        '  properties (SetAccess = private, Dependent)\n', ...
        '    anotherProp;\n', ...
        '  end\n', ...
        '  methods\n', ...
        '    function self = AClass\n', ...
        '      fprintf(''hello world!'');\n', ...
        '    end\n', ...
        '  end\n', ...
        '  methods (Access = private)\n', ...
        '    function x = aMethod(self)\n', ...
        '      fprintf(''hello world!'');\n', ...
        '    end\n', ...
        '  end\n', ...
        'end\n' ...
    ]);
end

function test_classdef_line_not_executable
    mfile = MOcovMFile(create_classdef);
    executable_lines = get_lines_executable(mfile);
    assert(~executable_lines(1), ...
        '`classdef` line is wrongly classified as executable');
end

function test_methods_opening_section_not_executable
    mfile = MOcovMFile(create_classdef);

    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    method_opening = [8, 13];

    for l = method_opening
      assert(~executable_lines(l), ...
          '`%s` line is wrongly classified as executable', lines{l});
    end
end

function test_method_body_executable
    mfile = MOcovMFile(create_classdef);

    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    method_lines = [10, 15];

    for l = method_lines
      assert(executable_lines(l), ...
          '`%s` line is wrongly classified as non-executable', lines{l});
    end
end

function test_properties_line_not_executable
    mfile = MOcovMFile(create_classdef);

    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    properties_lines = [2:4, 5:7];

    for l = properties_lines
      assert(~executable_lines(l), ...
          '`%s` line is wrongly classified as executable', lines{l});
    end
end
