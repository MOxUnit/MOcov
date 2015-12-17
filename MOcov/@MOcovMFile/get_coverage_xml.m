function xml=get_coverage_xml(obj, root_dir)
    relative_fn=mocov_get_relative_path(root_dir,obj.filename);

    [pth,nm,ext]=fileparts(relative_fn);

    r=get_coverage_ratio(obj);

    % for now, consider all functions as being in one package
    % and treat them all as one big file
    header=sprintf(['<class name="%s" filename="%s" '...
                        'line-rate="%.3f" '...
                        'branch-rate="1.0">\n'...
                        '<methods></methods>'],...
                    nm,relative_fn,r);
    footer='</class>';

    body=get_reportable_lines_xml(obj);
    xml=sprintf('%s',header,body,footer);



function xml=get_reportable_lines_xml(obj)
    idxs=find(obj.executable);
    n=numel(idxs);

    lines=cell(1,n);
    for k=1:n
        idx=idxs(k);
        if obj.executed(idx)
            hits=1;
        else
            hits=0;
        end
        lines{k}=sprintf('<line number="%d" hits="%d" branch="false"/>',...
                        idx,hits);
    end

    xml=sprintf('%s\n','<lines>',lines{:},'</lines>');


function r=get_coverage_ratio(obj)
    r=sum(obj.executed & obj.executable) / sum(obj.executable);