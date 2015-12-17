function write_lines_with_prefix(obj, fn, decorator)

    n=numel(obj.lines);

    new_lines=cell(1,n);
    for k=1:n
        line=obj.lines{k};
        if obj.executable(k)
            line=[decorator(k), line];
        end

        new_lines{k}=[line sprintf('\n')];
    end

    pth=fileparts(fn);
    mkdir_recursively(pth);

    fid=fopen(fn,'w');
    cleaner=onCleanup(@()fclose(fid));
    all_lines=cat(2,new_lines{:});
    fprintf(fid,'%s',all_lines);


function mkdir_recursively(pth)
    if ~isempty(pth) && ~isdir(pth)
        parent=fileparts(pth);
        mkdir_recursively(parent);
        mkdir(pth);
    end