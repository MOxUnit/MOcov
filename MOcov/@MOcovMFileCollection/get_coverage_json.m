function json=get_coverage_json(obj)
% Get JSON coverage representation
%
% json=get_coverage_json(obj)
%
% Inputs:
%   obj                 MOcovMFileCollection instance
%
% Output:
%   json                JSON String representation of coverage, with
%                       elements:
%                       'service_job_id' Travis job id
%                       'service_name'   'travis-ci' when running on Travis
%                       'source_files'   Array with JSON representation
%                                        of MOcovMFile instances
%
% Notes:
%   - this output can be used by the coveralls.io online coverage service
%     in combination with travis-ci

    abs_root_dir=mocov_get_absolute_path(obj.root_dir);
    git_root_dir=mocov_util_get_root_path_containing('.git',abs_root_dir);

    service=get_service_params();
    source_files_json_cell=cellfun(@(mfile)get_coverage_json(mfile,...
                                git_root_dir),...
                                obj.mfiles,...
                                'UniformOutput',false);
    source_files_json=strjoin(source_files_json_cell,',');
    json=sprintf(['{ \n',...
                    '"service_job_id": "%s",\n',...
                    '"service_name": "%s",\n',...
                    '"source_files": [\n%s\n]\n',...
                    '}\n'],...
                    service.job_id,...
                    service.service_name,...
                    source_files_json);



function params=get_service_params()
    params=struct();
    if ~isequal(getenv('CI'),'true')
        % run locally
        params.job_id='none';
        params.service_name='none';
        return;
    end

    if isequal(getenv('TRAVIS'),'true')
        params.service_name='travis-ci';
        params.job_id=getenv('TRAVIS_JOB_ID');

        return;
    end

    params.job_id='job id unknown';
    params.service_name='service name unknown';
