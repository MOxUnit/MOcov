function test_suite = test_MOcovMFile_recognizes_classdef_syntax
    initTestSuite;
end

function filepath = create_classdef(classname)
    if nargin < 1
      classname = 'AClass';
    end

    filepath = create_tempfile([classname, '.m'], [ ...
        'classdef ', classname, ' < handle\n', ...
        '  properties\n', ...
        '    aProp;\n', ...
        '  end\n', ...
        '  properties (SetAccess = private, Dependent)\n', ...
        '    anotherProp;\n', ...
        '  end\n', ...
        '  methods\n', ...
        '    function self =  ', classname, ' \n', ...
        '      fprintf(0, ''hello world!'');\n', ...
        '    end\n', ...
        '  end\n', ...
        '  methods (Access = public)\n', ...
        '    function x = aMethod(self)\n', ...
        '      fprintf(0, ''hello world!'');\n', ...
        '    end\n', ...
        '  end\n', ...
        'end\n' ...
    ]);
end

function test_classdef_line_not_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);

    assertStringContains(lines{1}, 'classdef');
    assert(~executable_lines(1), ...
        '`classdef` line is wrongly classified as executable');
end

function test_methods_opening_section_not_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    method_opening = [8, 13];

    for n = method_opening
      assertStringContains(lines{n}, 'methods');
      assert(~executable_lines(n), ...
          '`%s` line is wrongly classified as executable', lines{n});
    end
end

function test_method_body_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    method_lines = [10, 15];

    for n = method_lines
      assertStringContains(lines{n}, 'fprintf');
      assert(executable_lines(n), ...
          '`%s` line is wrongly classified as non-executable', lines{n});
    end
end

function test_properties_line_not_executable
    % Test subject: `MOcovMFile` constructor

    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    properties_opening = [2, 5];
    properties_body = [3, 6];

    for n = properties_opening
      assertStringContains(lines{n}, 'properties');
      assert(~executable_lines(n), ...
          '`%s` line is wrongly classified as executable', lines{n});
    end

    for n = properties_body;
      assertStringContains(lines{n}, 'Prop;');
      assert(~executable_lines(n), ...
          '`%s` line is wrongly classified as executable', lines{n});
    end
end

function test_generate_valid_file
    % Test subject: `write_lines_with_prefix` method

    originalPath = path;
    pathCleanup = onCleanup(@() path(originalPath));

    % Given:

    % `AClass.m` file with a classdef declaration
    tempfile = create_classdef('AClass');
    tempfileCleanup = onCleanup(@() delete(tempfile));

    % a folder where mocov will store the decorated files
    tempfolder = create_tempfolder(['mocovtest', num2str(randi(99999999999))]);
    decorated = fullfile(tempfolder, 'AClass.m');
    tempfolderCleanup = onCleanup(@() rmdir(tempfolder, 's'));

    % a valid decorator
    decorator = @(line_number) ...
      sprintf('fprintf(0, ''%s:%d'');', tempfile, line_number);


    % When: the decorated file is generated
    mfile = MOcovMFile(tempfile);
    write_lines_with_prefix(mfile, decorated, decorator);


    % Then: the decorated file should have a valid syntax
    % Since Octave do not have a linter, run the code to check the syntax.
    addpath(tempfolder);
    try
      aObject = AClass();
      aObject.aMethod();
    catch
      assert(false, ['Problems when running the decorated file: `%s` ', ...
                     'please check for syntax errors.'], decorated);
    end
end
