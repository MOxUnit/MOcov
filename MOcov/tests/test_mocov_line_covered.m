function test_suite = test_mocov_line_covered
    initTestSuite;


function test_mocov_line_covered_basics()
    initial_state=mocov_line_covered();
    cleaner=onCleanup(@()mocov_line_covered(initial_state));

    s=struct();
    s.keys={'a';'c'};
    s.lines={[false true true false true],[false true]};

    % set the state and query it
    mocov_line_covered(s);
    s2=mocov_line_covered(s);
    assertEqual(s,s2);

    % set a couple of lines covered, and verify the state is updated
    mocov_line_covered('a',4);
    mocov_line_covered('b',3);

    s=struct();
    s.keys={'a';'b';'c'};
    s.lines={[false true true true true],...
                        [false false true],...
                        [false true]};
    s2=mocov_line_covered();

    assertEqual(s.keys,s2.keys);
    n=numel(s.lines);
    assertEqual(n,numel(s2.lines));
    for k=1:n
        assertEqual(find(s.lines{k}(:)),find(s2.lines{k}(:)));
    end





