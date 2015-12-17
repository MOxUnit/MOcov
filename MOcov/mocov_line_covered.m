function state=mocov_line_covered(varargin)
% sets a line in an mfile to 'covered' state
%
% Usages:
%   1) state=mocov_line_covered();
%
%      Queries the current state
%
%   2) mocov_line_covered(state)
%
%      Sets the state
%
%   3) mocov_line_covered(filename, line_number)
%
%      Sets that line 'line_number' in file 'filename' is covered
%
% NNO May 2014


    persistent cached_keys;
    persistent cached_lines;
    persistent cached_last_index;

    % initialize persistent variables, if necessary
    if isnumeric(cached_keys)
        cached_keys=cell(0);
        cached_lines=cell(0);
        cached_last_index=[];
    end

    switch nargin
        case 0
            % query the state
            state=struct();
            state.keys=cached_keys;
            state.lines=cached_lines;
            return;

        case 1
            % set the state
            state=varargin{1};
            if isempty(state)
                state.keys=cell(0);
                state.lines=cell(0);
            end

            cached_keys=state.keys;
            cached_lines=state.lines;
            cached_last_index=[];
            return

        case 2
            % add a line covered
            key=varargin{1};
            line=varargin{2};
            state=[];

        otherwise
            error('illegal input');
    end



    if isempty(cached_last_index) || ...
                ~isequal(cached_keys{cached_last_index}, key)
        [index, found]=find_key(cached_keys,key);
        cached_last_index=index;
        if ~found
            empty_lines=false(10,1);
            cached_keys=[cached_keys(1:(index-1)); ...
                            {key};
                          cached_keys(index:end)];

            cached_lines=[cached_lines(1:(index-1)); ...
                            {empty_lines};
                          cached_lines(index:end)];

        end
    end

    if line>numel(cached_lines{cached_last_index})
        cached_lines{cached_last_index}(2*line)=false;
    end

    cached_lines{cached_last_index}(line)=true;


function [index, found]=find_key(haystack,needle)
    % binary search for needle in haystack
    %
    % - if needle is in haystack, then haystack{index}==needle and
    %   found=true
    % - otherwise, haystack{p} < needle for all p < index,
    %   haystack{p} > needle for all p >= index, and found=false

    n=numel(haystack);

    if n==0
        index=1;
        found=false;
        return;
    end

    needle_cell={needle};

    if is_less(needle_cell,haystack(1))
        index=1;
        found=false;
    elseif is_less(haystack(end),needle_cell)
        index=n+1;
        found=false;
    else
        first=1;
        last=n;

        while first<last
            index=floor((first+last)/2);
            if index==first
                break;
            end

            if is_less_or_equal(needle_cell,haystack(index));
                last=index;
            else
                first=index;
            end
        end

        if isequal(haystack{index},needle)
            index=first;
        else
            index=last;
        end

        found=isequal(haystack{index},needle);

    end



function tf=is_less(a,b)
    tf=is_less_or_equal(a,b) && ~isequal(a,b);

function tf=is_less_or_equal(a,b)
     [unused,i]=sort([a,b]);
     tf=i(1)==1;






