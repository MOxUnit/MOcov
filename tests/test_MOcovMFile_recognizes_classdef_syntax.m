function test_suite = test_MOcovMFile_recognizes_classdef_syntax
    initTestSuite;
end

function folderpath = create_tempfolder(foldername)
    % Create a folder inside the default temporary director
    % and returns it path.
    %
    % If the folder already exists, do nothing...

    len = length(tempdir);
    if length(foldername) >= len && strcmp(foldername(1:len), tempdir)
        % Just ignore if foldername already include the tempdir path
        folderpath = foldername;
    else
        folderpath = fullfile(tempdir, foldername);
    end

    [unused, unused, unused] = mkdir(folderpath);
    % Avoid existing folder warnings by receiving all the 3 outputs of mkdir
end


function filepath = create_tempfile(filename, contents)
    filepath = fullfile(tempdir, filename);

    % Make sure eventual folder exists
    tempfolder = fileparts(filepath);
    create_tempfolder(tempfolder);

    fid = fopen(filepath, 'w');
    fprintf(fid, contents);
    fclose(fid);
end

function filepath = create_classdef
    filepath = create_tempfile('AClass.m', [ ...
        'classdef AClass < handle\n', ...
        '  properties\n', ...
        '    aProp;\n', ...
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

function assertStringContains(text, subtext)
  assert(~isempty(strfind(text, subtext)), ...
    'String ''%s'' should contain ''%s'', but it doesn''t.');
end

function test_classdef_line_not_executable
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
    tempfile = create_classdef;
    teardown = onCleanup(@() delete(tempfile));

    mfile = MOcovMFile(tempfile);
    lines = get_lines(mfile);
    executable_lines = get_lines_executable(mfile);
    properties_lines = [3, 6];

    for n = properties_lines
      assertStringContains(lines{n}, 'Prop;');
      assert(~executable_lines(n), ...
          '`%s` line is wrongly classified as executable', lines{n});
    end
end
