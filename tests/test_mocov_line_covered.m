function test_suite = test_mocov_line_covered
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions = localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_mocov_line_covered_basics()
    initial_state = mocov_line_covered();
    cleaner = onCleanup(@()mocov_line_covered(initial_state));
    aet = @(varargin)assertExceptionThrown(@() ...
                                           mocov_line_covered(varargin{:}));

    s = struct();
    s.keys = {'a'; 'c'};
    s.line_count = {[0; 1; 3; 2; 0]; ...
                    [0; 10]};

    % set the state and query it
    mocov_line_covered(s);
    s2 = mocov_line_covered(s);
    assertEqual(s, s2);

    % set a couple of lines covered, and verify the state is updated
    mocov_line_covered(1, 'a', 4);
    mocov_line_covered(1, 'a', 5);
    
    mocov_line_covered(3, 'b', 3);
    mocov_line_covered(2, 'c', 4);
    mocov_line_covered(2, 'c', 104);
    mocov_line_covered(2, 'c', 104);

    s = struct();
    s.keys = {'a'; 'c'; 'b'};
    s.line_count = {[0; 1; 3; 3; 1]; ...
                    [0; 10; 0; 1]; ...
                    [0; 0; 1; zeros(100,1 ); 2]};
    t = mocov_line_covered();
    assert_state_equal(s, t)

function assert_state_equal(s, t)
    assertEqual(sort(fieldnames(s)), {'keys'; 'line_count'});
    assertEqual(sort(fieldnames(t)), {'keys'; 'line_count'});

    n_items=max(find(isempty(s.keys),1),find(isempty(t.keys),1));
    assertEqual(s.keys(1:n_items), t.keys(1:n_items));

    for k=1:n_items
        s_lines = s.line_count{k};
        t_lines = t.line_count{k};

        s_msk = s_lines > 0;
        t_msk = t_lines > 0;
        
        assertEqual(find(s_msk), find(t_msk));
        assertEqual(s_lines(s_msk), s_lines(t_msk));
    end    
