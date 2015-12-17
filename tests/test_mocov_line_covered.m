function test_suite = test_mocov_line_covered
    initTestSuite;


function test_mocov_line_covered_basics()
    initial_state=mocov_line_covered();
    cleaner=onCleanup(@()mocov_line_covered(initial_state));
    aet=@(varargin_assertExceptionThrown(@()...
                        mocov_line_covered(varargin{:}));

    s=struct();
    s.keys={'a';'c'};
    s.line_count={[0 1 3 2 0];...
                [0 10]};

    % set the state and query it
    mocov_line_covered(s);
    s2=mocov_line_covered(s);
    assertEqual(s,s2);

    % set a couple of lines covered, and verify the state is updated
    mocov_line_covered(1,'a',4,2);
    mocov_line_covered(1,'a',5,1);
    aet(2,'b',3,1); % wrong name
    mocov_line_covered(3,'b',3,1);
    mocov_line_covered(2,'c',4,1);

    s=struct();
    s.keys={'a';'b';'c'};
    s.line_count={[0 1 3 4 1];...
                [0 0 1];...
                [0 10 0 1]};
    s2=mocov_line_covered();

    assertEqual(s.keys,s2.keys);
    n=numel(s.line_count);
    assertEqual(n,numel(s2.line_count));
    for k=1:n
        s_lines=s.line_count{k};
        s2_lines=s2.line_count{k};

        m=s_lines>0;
        m2=s2_lines>0;

        assertEqual(find(m),find(m2));
        assertEqual(s_lines(m),s_lines(m2));
    end





