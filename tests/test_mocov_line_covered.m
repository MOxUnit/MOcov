function test_suite = test_mocov_line_covered
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function s = get_base_state()
    s = struct();
    s.keys = {'a'; 'c'};
    s.line_count = {[0; 1; 3; 2; 0]; ...
                    [0; 10]};

function test_mocov_line_covered_set_and_get()
    initial_state = mocov_line_covered();
    cleaner = onCleanup(@()mocov_line_covered(initial_state));

    s = get_base_state();

    % set the state and query it
    mocov_line_covered(s);
    s_actual = mocov_line_covered(s);
    assert_state_equal(s, s_actual);

function test_mocov_line_covered_updates()
    initial_state = mocov_line_covered();
    cleaner = onCleanup(@()mocov_line_covered(initial_state));

    % set state
    s = get_base_state();
    mocov_line_covered(s);

    % set a couple of lines covered, and verify the state is updated
    mocov_line_covered(1, 'a', 4);
    mocov_line_covered(1, 'a', 5);

    mocov_line_covered(3, 'b', 3);
    mocov_line_covered(2, 'c', 4);
    mocov_line_covered(2, 'c', 104);
    mocov_line_covered(2, 'c', 104);

    s_expected = struct();
    s_expected.keys = {'a'; 'c'; 'b'};
    s_expected.line_count = {[0; 1; 3; 3; 1]; ...
                             [0; 10; 0; 1]; ...
                             [0; 0; 1; zeros(100, 1); 2]};
    s_actual = mocov_line_covered();
    assert_state_equal(s_actual, s_expected);

function test_mocov_line_covered_exceptions()
    initial_state = mocov_line_covered();
    cleaner = onCleanup(@()mocov_line_covered(initial_state));

    invalid_args = {{struct}         % missing keys
                    {1, 'not_a', 1}  % different file
                    {1.5, 'a', 1}    % non-integer
                    {1, 1, 1}    % non-integer
                    {1, 'a', [1 2]}  % non singleton
                    {[1 2], 'a', 1}  % non singleton
                   };
    n = numel(invalid_args);
    for k = 1:n
        % set state
        s_base = get_base_state();
        mocov_line_covered(s_base);
        args = invalid_args{k};
        assertExceptionThrown(@()mocov_line_covered(args{:}));

        % verify state is maintained after exception was raised
        s_after = mocov_line_covered();
        assert_state_equal(s_base, s_after);
    end

function assert_state_equal(s, t)
    assertEqual(sort(fieldnames(s)), {'keys'; 'line_count'});
    assertEqual(sort(fieldnames(t)), {'keys'; 'line_count'});

    n_items = max(find(isempty(s.keys), 1), find(isempty(t.keys), 1));
    assertEqual(s.keys(1:n_items), t.keys(1:n_items));

    for k = 1:n_items
        s_lines = s.line_count{k};
        t_lines = t.line_count{k};

        s_msk = s_lines > 0;
        t_msk = t_lines > 0;

        assertEqual(find(s_msk), find(t_msk));
        assertEqual(s_lines(s_msk), s_lines(t_msk));
    end
