function write_tInfo( subjects, tasks )

% tasks = {'contrast','localizer'}

% due to slowness of tInfo construction, those tables must be setup before
% the scanning session. This script is designed to do that. Though, it is
% not yet fully automated, given that the opening diagogue box still
% appears at start

for sub = subjects
    for task = tasks
        if strcmp(task,'contrast')
            max_runs = 10;
        elseif strcmp(task,'localizer')
            max_runs = 4;
        end
        for run = 0:max_runs
            main('debugLevel', 10, 'responder', 'setup','subject', sub, 'experiment', task{1}, 'run', run, 'refreshRate', 60);
        end
    end
end

end

