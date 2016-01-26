# MOcov [![Build Status](https://travis-ci.org/MOcov/MOcov.svg?branch=master)](https://travis-ci.org/MOcov/MOcov)

MOcov is a coverage report generator for Matlab and GNU Octave.

### Features

- Runs on both the [Matlab] and [GNU Octave] platforms.
- Can be used directly with continuous integration services, such as [coveralls-io] and [Shippable].
- Integrates with MOxUnit, a unit test framework for Matlab and GNU Octave.
- Supports the Matlab profiler.
- Writes coverage reports in HTML, JSON and XML formats.
- Distributed under the MIT license, a permissive free software license.


### Installation

- Using the shell (requires a Unix-like operating system such as GNU/Linux or Apple OSX):

    ```bash
    git clone https://github.com/MOcov/MOcov.git
    cd MOcov
    make install
    ```
    This will add the MOxUnit directory to the Matlab and/or GNU Octave searchpath. If both Matlab and GNU Octave are available on your machine, it will install MOxUnit for both.

- Manual installation:

    + Download the zip archive from the [MOxUnit] website.
    + Start Matlab or GNU Octave.
    + On the Matlab or GNU Octave prompt, `cd` to the `MOxUnit` root directory, then run:
    
        ```matlab
        cd MOcov            % cd to MOcov subdirectory
        addpath(pwd)        % add the current directory to the Matlab/GNU Octave path
        savepath            % save the path
        ```

### Generating coverage reports

There are two methods to generate coverage while evaluating a particular expression:

1) the 'file' method takes a directory with files for which coverage is to be determined, rewrites all files in that directory so that coverage of each line is recorded, stores them in a temporary directory, and adds the temporary directory to the path. (After coverage reportes have been generated, the temporary files are deleted and the path is restored). This method runs on both GNU Octave and Matlab, but is typically slow.

2) the 'profile' method uses the Matlab profiler. This method runs on Matlab only, but is generally faster.

### Use cases

Typical use cases for MOcov are:

-   locally run code with coverage for code in a unit test framework on GNU Octave or Matlab. Use

    ```matlab    
        mocov('-cover','path/with/code',...
                '-expression','run_test_command',...
                '-cover_json_file','coverage.json',...
                '-cover_xml_file','coverage.xml',...
                '-cover_html_dir','coverage_html',
                '-method','file');
    ```

    to generate coverage reports for all files in the `'path/with/code'` directory when `running eval('run_test_command')`. Results are stored in JSON, XML and HTML formats.

-   as a specific example of the use case above, when using the [MOxUnit] unit test platform such tests can be run as

    ```matlab
        success=moxunit_runtests('path/with/tests',...
                                    '-with_coverage',...
                                    '-cover','/path/with/code',...
                                    '-cover_xml_file','coverage.xml',...
                                    '-cover_html_dir','coverage_html');
    ```

    where `'path/with/tests'` contains unit tests. 

-   On the Matlab platform, results from `profile('info')` can be stored in JSON, XML or HTML formats directly. In the following:

    ```matlab
        % enable profiler
        profile on;

        % run code for which coverage is to be determined
        <your code here>

        % write coverage based on profile('info')
        mocov('-cover','path/with/code',...
                '-profile_info',...
                '-cover_json_file','coverage.json',...
                '-cover_xml_file','coverage.xml',...
                '-cover_html_dir','coverage_html',
                '-method','file');
    ```

    coverage results are stored in JSON, XML and HTML formats.

-   use with continuous integration service, such as [Shippable] or [travis-ci] combined with [coveralls.io]. See the .travis.yml in the MOxUnit project for an example.


### Use with travis-ci and Shippable
MOcov can be used with the [Travis-ci] and [Shippable] service for continuous integration testing. This is achieved by setting up a [.travis.yml configuration file](.travis.yml).

Due to recursiveness issues, MOcov cannot use these services to generate coverage reports for itself. For an example, see the [MOxUnit .travis.yml] file.

### Compatibility notes
- Because GNU Octave 3.8 and 4.0 do not support `classdef` syntax, 'old-style' object-oriented syntax is used for the class definitions. 


### Contact
Nikolaas N. Oosterhof, nikolaas dot oosterhof at unitn dot it


### License

(The MIT License)

Copyright (c) 2015 Nikolaas N. Oosterhof

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



[GNU Octave]: http://www.gnu.org/software/octave/
[Matlab]: http://www.mathworks.com/products/matlab/
[MOxUnit]: https://github.com/MOxUnit/MOxUnit
[MOxUnit .travis.yml]: https://github.com/MOxUnit/MOxUnit/blob/master/.travis.yml
[Travis-ci]: https://travis-ci.org
[coveralls.io]: https://coveralls.io/
[travis.yml configuration file]: https://docs.travis-ci.com/user/customizing-the-build/
[Shippable]: https://shippable.com


