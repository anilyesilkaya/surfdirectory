function sd(varargin)
    %SD  SurfDirectory: enhanced "cd" with history + bookmarks + files.
    %
    %   Type:
    %       sd
    %   to print the full usage help.
    prefGroup     = "surfdirectory";
    bookmarksName = "bookmarks";
    historyName   = "history";
    filesName     = "files";
    
    % --- Initialization ---
    
    % Fetch the existing bookmarks, otherwise initialize
    if ~ispref(prefGroup, bookmarksName)
        bookmarks = initBookmarks(prefGroup, bookmarksName);
    else
        bookmarks = getpref(prefGroup, bookmarksName);
    end
    
    % Fetch the existing history, otherwise initialize
    if ~ispref(prefGroup, historyName)
        history = initHistory(prefGroup, historyName);
    else
        history = getpref(prefGroup, historyName);
    end
    
    % Fetch the existing opened files, otherwise initialize
    if ~ispref(prefGroup, filesName)
        files = initFiles(prefGroup, filesName);
    else
        files = getpref(prefGroup, filesName);
    end
    
    % --- surf code ---
    try
        if nargin == 0
            showHelp(); % Show the help text
        elseif nargin == 1
            % Jump into the requested directory
            history = jump2directory(history, varargin{1});
        elseif nargin == 2 && strcmp(varargin{1}, "go")
            switch varargin{2}
                case {"matlabroot", "root"}
                    if contains(matlabroot, "runnable")
                        history = jump2directory(history, erase(matlabroot, "/runnable"));
                    else
                        history = jump2directory(history, matlabroot);
                    end
                case {"back", "b"}
                    if history(1).cursor > 1
                        history(1).cursor = history(1).cursor - 1;
                        cd(history(history(1).cursor).source)
                    end
                case {"fwd", "f"}
                    if history(1).cursor < numel(history)
                        history(1).cursor = history(1).cursor + 1;
                        cd(history(history(1).cursor).source)
                    end
            end
        elseif nargin == 2 && strcmp(varargin{1}, "book")
            switch varargin{2}
                case "show"
                    if isConfigured(bookmarks)
                        disp(entries(bookmarks))
                    end
                case "export"
                    save("bookmarks.mat","bookmarks")
                case "load"
                    data = load("bookmarks.mat");
                    bookmarks = data.bookmarks;
                case "clear"
                    bookmarks = initBookmarks(prefGroup, bookmarksName);  % clear bookmarks
            end
        elseif nargin == 2 && strcmp(varargin{1}, "hist")
            switch varargin{2}
                case "show"
                    showHistory(history)
                case "clear"
                    history = initHistory(prefGroup, historyName); % clear history
            end
        elseif nargin == 2 && strcmp(varargin{1}, "files")
            switch varargin{2}
                case "show"
                    if isConfigured(files)
                        disp(entries(files))
                    end
                case "clear"
                    files = initFiles(prefGroup, filesName); % clear files
            end
        elseif nargin == 3 && strcmp(varargin{1}, "files")
            switch varargin{2}
                case "open"
                    % Open the file in the given entry
                    if isConfigured(files)
                        % Open the file if alias matches
                        if isKey(files, varargin{3})
                            % Convert relative matlabroot to an absolute path
                            resPath = files(varargin{3});
                            if contains(resPath, "<$matlabroot$>")
                                % Convert relative matlabroot to an absolute path
                                resPath = resolvePath(files(str2double(varargin{3})).filepath);
                            end
                            % Open the file after the conversion
                            edit(resPath)
                        end
                    end
                case "remove"
                    % Remove the given entry (based on the item ID)
                    files = remove(files, varargin{2});
            end
        elseif nargin == 4 && strcmp(varargin{1}, "files")
            switch varargin{2}
                case "$add"
                    % Check if it's a valid file and key doesn't exist
                    if exist(varargin{3}, "file") == 2
                        % Add a new file bookmark (absolute path)
                        files(varargin{4}) = fullfile(string(pwd), varargin{3});
                    else
                        warning("Requested file is not in the current path.")
                    end
                case "add"
                    % Check if it's a valid file and key doesn't exist
                    if exist(varargin{3}, "file") == 2
                        % Add a new bookmark (relative path)
                        if contains(pwd, matlabroot)
                            curPath = pwd;
                            curPath = erase(curPath, matlabroot);
                            % Is files initialized
                            files(varargin{4}) = fullfile(string(curPath), varargin{3});
                        else
                            warning("Path doesn't contain matlabroot!")
                        end
                    else
                        warning("Requested file is not in the current path.")
                    end
            end
        elseif nargin == 3 && strcmp(varargin{1}, "hist") && strcmp(varargin{2}, "go")
            % Jump to the directory with the user requested index
            history = jump2directory(history, history(str2double(varargin{3})).destination);
        elseif nargin == 3 &&  strcmp(varargin{1}, "book")
            switch varargin{2}
                case "go"
                    if contains(bookmarks(varargin{3}), "<$matlabroot$>")
                        % Convert relative matlabroot to an absolute path
                        resPath = resolvePath(bookmarks(varargin{3}));
                    else
                        resPath = bookmarks(varargin{3});
                    end
                    % Jump to the directory after the conversion
                    history = jump2directory(history, resPath);
                case "$add"
                    % Add a new bookmark (absolute path)
                    bookmarks(varargin{3}) = string(pwd);
                case "add"
                    % Add a new bookmark (relative path)
                    if contains(pwd, matlabroot)
                        curPath = pwd;
                        curPath = erase(curPath, matlabroot);
                        bookmarks(varargin{3}) = string(fullfile("<$matlabroot$>", curPath));
                    else
                        warning("Path doesn't contain matlabroot!")
                    end
                case "remove"
                    bookmarks = remove(bookmarks, varargin{3});
            end
        end
        setpref(prefGroup, bookmarksName, bookmarks);
        setpref(prefGroup, historyName, history);
        setpref(prefGroup, filesName, files);
    catch e
        throw(e)
    end
end

% Local helper functions

function absPath = resolvePath(path)
    if contains(path, "<$matlabroot$>")
        absPath = fullfile(replace(path, "<$matlabroot$>", matlabroot));
    end
end

function showHistory(history)
    % Create and show history table
    history_tmp = arrayfun(@(x,y) setfield(x,'item',y), history, 1:numel(history));
    history_tmp = rmfield(history_tmp, 'cursor');
    history_tmp = orderfields(history_tmp, {'item','destination','source','last_accessed'});
    disp(struct2table(history_tmp))
end

function history = jump2directory(history, target)
    % Log the source
    history(end+1).source = string(pwd);
    
    % cd into the destination
    cd(target)
    
    % Log the destination
    history(end).destination = string(pwd);
    history(end).last_accessed = string(datetime("now"));
    history(1).cursor = history(1).cursor + 1;
end

function bookmarks = initBookmarks(prefGroup, bookmarksName)
    % The reserved token <$matlabroot$> is used to prevent
    % collisions with user-defined bookmarks.
    bookmarks = dictionary("matlabroot", "<$matlabroot$>", "root", "<$matlabroot$>");
    setpref(prefGroup, bookmarksName, bookmarks);
end

function history = initHistory(prefGroup, historyName)
    history = struct("source", pwd, "destination", pwd, "last_accessed", string(datetime("now")), 'cursor', 1);
    setpref(prefGroup, historyName, history);
end

function files = initFiles(prefGroup, filesName)
    files = dictionary();
    setpref(prefGroup, filesName, files);
end

function showHelp
    fprintf("%s", helpText());
end

function txt = helpText()
    txt = sprintf([ ...
        '\n------------------------------------------------\n' ...
        'SurfDirectory (sd)\n' ...
        '------------------------------------------------\n\n' ...
        'Usage:\n' ...
        '  sd\n' ...
        '      Show this help.\n\n' ...
        '  sd <directory>\n' ...
        '      Change directory to <directory> and log in history.\n\n' ...
        'Go shortcuts:\n' ...
        '  sd go matlabroot | root\n' ...
        '      Jump to MATLAB root.\n' ...
        '  sd go back | b\n' ...
        '      Jump back one step (previous source folder).\n' ...
        '  sd go fwd  | f\n' ...
        '      Jump forward one step.\n\n' ...
        'Bookmarks:\n' ...
        '  sd book show\n' ...
        '      Display bookmarks.\n' ...
        '  sd book $add <name>\n' ...
        '      Add bookmark <name> for the current folder (absolute path).\n' ...
        '  sd book add <name>\n' ...
        '      Add bookmark <name> for the current folder (relative to matlabroot).\n' ...
        '  sd book remove <name>\n' ...
        '      Remove bookmark <name>.\n' ...
        '  sd book go <name>\n' ...
        '      Jump to bookmark <name>.\n' ...
        '  sd book export\n' ...
        '      Save bookmarks to bookmarks.mat (current folder).\n' ...
        '  sd book load\n' ...
        '      Load bookmarks from bookmarks.mat (current folder).\n' ...
        '  sd book clear\n' ...
        '      Clear bookmarks (reinitialize defaults).\n\n' ...
        'History:\n' ...
        '  sd hist show\n' ...
        '      Display history.\n' ...
        '  sd hist clear\n' ...
        '      Clear history (reinitialize).\n' ...
        '  sd hist go <index>\n' ...
        '      Jump to history entry <index>.\n\n' ...
        'Files:\n' ...
        '  sd files show\n' ...
        '      Display file entries.\n' ...
        '  sd files $add <filename>\n' ...
        '      Add a file entry for <filename> in the current folder (absolute path).\n' ...
        '  sd files add <filename>\n' ...
        '      Add a file entry for <filename> in the current folder (relative to matlabroot).\n' ...
        '  sd files remove <index>\n' ...
        '      Remove file entry <index>.\n' ...
        '  sd files open <index>\n' ...
        '      Open file entry <index> in the editor.\n\n' ...
        'Notes:\n' ...
        '  - Bookmarks, history, and files are stored in preferences under group "surfdirectory".\n\n' ...
        ]);
end
