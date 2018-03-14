function version = get_version_string(fname, fallback)

% The 'fname' argument should be a character array specifying a file name that can be
% opened by fopen. The file should contain a single line specifying the
% version string, any data beyond the first line is ignored.

% If the file does not exist, cannot be opened in read mode, or is empty,
% then the version string is set to the value specified in the optional 'fallback'
% argument. The default value for the fallback version string is 'dev'.

    if nargin == 1
        fallback = 'dev';
    end
    
    not_found = false;
    unable_to_read = false;

    if exist(fname, 'file')
       try
           fileID = fopen(fname,'r');
           try
                version = fgetl(fileID);
                if version == -1
                    error('File %s is empty', fname);
                else
                    next_line = fgetl(fileID);
                    if ischar(next_line)
                        warning('Ignoring all data in file %s past first line', fname);
                    end
                end
                fclose(fileID);                
           catch
                unable_to_read = true;
                fclose(fileID);
           end
       catch
           not_found = true;
       end
    else
        not_found = true;
    end
    
    if not_found || unable_to_read
        version =  fallback;
    end
    
    if not_found
        warning('File %s not found, setting version string to ''%s''', fname, version);
    end
    
    if unable_to_read
        warning('Unable to read version string from file, setting version string to %s', fname, version);
    end
end