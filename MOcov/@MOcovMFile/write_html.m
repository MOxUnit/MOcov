function write_html(obj, fn, index_fn)
    mfile_fn=obj.filename;

    fid=fopen(fn,'w');
    cleaner=onCleanup(@()fclose(fid));


    fprintf(fid,['<html><head><title>%s</title></head>'...
                        '<body>'...
                        '<p>(Back to <a href="%s">index</a>)</p>'...
                        '<h1>%s</h1>'...
                        '<p style="font-family:'...
                        '''Courier New''">'...
                        '<table>\n'],...
                        mfile_fn,index_fn,mfile_fn);
    fprintf(fid,'<tr><th>Line</th><th>Code</th></tr>\n');

    lines=obj.lines;
    missed=obj.executable & ~obj.executed;

    html_red_color='#FF0000';
    html_white_color='#FFFFFF';

    for k=1:numel(lines)
        line=convert_raw_to_html(lines{k});

        if missed(k)
            html_color=html_red_color;
        else
            html_color=html_white_color;
        end

        fprintf(fid,'<tr><td>%d</td><td bgcolor="%s">%s</td></tr>\n',...
                        k,html_color,line);
    end
    fprintf(fid,'</table></p></body></html>');


function line=convert_raw_to_html(line)
	orig_new= {' ','&nbsp';...
                '<','&lt';...
                '>','&gt';...
                '&','&ampersand'};

    n=size(orig_new,2);
    for k=1:n
        line=strrep(line,orig_new{k,1},orig_new{k,2});
    end
