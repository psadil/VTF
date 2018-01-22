function  write_tInfo( subjects )

% due to slowness of tInfo construction, those tables must be setup before
% the scanning session. This script is designed to do that. Though, it is
% not yet fully automated, given that the opening diagogue box still
% appears at start

for sub = subjects
    main('debugLevel',10,'responder', 'setup','subject',sub);
end

end

