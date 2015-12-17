function cleanup(obj)
    notify(obj.monitor,'Cleanup');
    if ~isempty(obj.orig_path)
        notify(obj.monitor,'','Resetting path');
        path(obj.orig_path);
    end

    if ~isempty(obj.temp_dir)
        msg=sprintf('Removing temporary files in %s',obj.temp_dir);
        notify(obj.monitor,'',msg);
        %%rmdir(obj.temp_dir,'s');
    end
