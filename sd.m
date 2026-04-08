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
            arg = varargin{1};
            navHandled = false;
            % Reserved navigation keywords (only when bare — no path separators)
            if ~contains(arg, '/') && ~contains(arg, '\')
                switch arg
                    case {"back", "b", "-"}
                        if history(1).cursor > 1
                            history(1).cursor = history(1).cursor - 1;
                            cd(history(history(1).cursor).source)
                        end
                        navHandled = true;
                    case {"fwd", "f"}
                        if history(1).cursor < numel(history)
                            history(1).cursor = history(1).cursor + 1;
                            cd(history(history(1).cursor).source)
                        end
                        navHandled = true;
                    case "book"
                        showBookmarks(bookmarks)
                        navHandled = true;
                    case "hist"
                        showHistory(history)
                        navHandled = true;
                    case "files"
                        showFiles(files)
                        navHandled = true;
                end
            end
            if ~navHandled
                try
                    history = jump2directory(history, arg);
                catch
                    warning("Folder not found: %s", arg)
                end
            end
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
                    showBookmarks(bookmarks)
                case "export"
                    save("bookmarks.mat", "bookmarks")
                case "load"
                    data = load("bookmarks.mat");
                    bookmarks = data.bookmarks;
                case "clear"
                    bookmarks = initBookmarks(prefGroup, bookmarksName);  % clear bookmarks
                otherwise
                    % Implicit go: treat as bookmark name
                    if isConfigured(bookmarks) && isKey(bookmarks, varargin{2})
                        if contains(bookmarks(varargin{2}), "<$matlabroot$>")
                            pth = resolvePath(bookmarks(varargin{2}));
                        else
                            pth = bookmarks(varargin{2});
                        end
                        history = jump2directory(history, pth);
                    else
                        warning("Bookmark not found: %s", varargin{2})
                    end
            end
        elseif nargin == 2 && strcmp(varargin{1}, "hist")
            switch varargin{2}
                case "show"
                    showHistory(history)
                case "clear"
                    history = initHistory(prefGroup, historyName); % clear history
                otherwise
                    % Implicit go: treat as history index
                    idx = str2double(varargin{2});
                    if ~isnan(idx) && idx >= 1 && idx <= numel(history)
                        history = jump2directory(history, history(idx).destination);
                    else
                        warning("Invalid history index: %s", varargin{2})
                    end
            end
        elseif nargin == 2 && strcmp(varargin{1}, "files")
            switch varargin{2}
                case "show"
                   showFiles(files)
                case "clear"
                    files = initFiles(prefGroup, filesName); % clear files
                case "export"
                    save("files.mat", "files")
                case "load"
                    data = load("files.mat", "files");
                    files = data.files;
                otherwise
                    % Implicit open: treat as file alias
                    if isConfigured(files) && isKey(files, varargin{2})
                        pth = files(varargin{2});
                        if contains(pth, "<$matlabroot$>")
                            pth = resolvePath(pth);
                        end
                        edit(pth)
                    else
                        warning("File alias not found: %s", varargin{2})
                    end
            end
        elseif nargin == 3 && strcmp(varargin{1}, "files")
            switch varargin{2}
                case {"open", "go"}
                    % Open the file in the given entry
                    if isConfigured(files)
                        % Open the file if alias matches
                        if isKey(files, varargin{3})
                            % Convert relative matlabroot to an absolute path
                            pth = files(varargin{3});
                            if contains(pth, "<$matlabroot$>")
                                % Convert relative matlabroot to an absolute path
                                pth = resolvePath(files(varargin{3}));
                            end
                            % Open the file after the conversion
                            edit(pth)
                        end
                    end
                case {"remove", "rm"}
                    % Remove the given entry (based on the item ID)
                    files = remove(files, varargin{3});
            end
        elseif nargin == 4 && strcmp(varargin{1}, "files")
            switch varargin{2}
                case "add"
                    % Check if it's a valid file and key doesn't exist
                    if exist(varargin{3}, "file") == 2
                        % Add a new file bookmark (absolute path)
                        files(varargin{4}) = fullfile(string(pwd), varargin{3});
                    else
                        warning("Requested file is not in the current path.")
                    end
                case "$add"
                    % Check if it's a valid file and key doesn't exist
                    if exist(varargin{3}, "file") == 2
                        % Add a new bookmark (relative path)
                        curPath = pwd;
                        if contains(curPath, matlabroot)
                            curPath = replace(curPath, matlabroot, "<$matlabroot$>");
                            % Is the files initialized
                            files(varargin{4}) = fullfile(string(curPath), varargin{3});
                        else
                            warning("Path doesn't contain matlabroot!")
                        end
                    else
                        warning("Requested file is not in the current path.")
                    end
            end
        elseif nargin == 4 && strcmp(varargin{1}, "book") && strcmp(varargin{2}, "add") && strcmp(varargin{4}, "--rel")
                % Add a new bookmark (relative path) via --rel flag
                if contains(pwd, matlabroot)
                    curPath = pwd;
                    curPath = erase(curPath, matlabroot);
                    bookmarks(varargin{3}) = string(fullfile("<$matlabroot$>", curPath));
                else
                    warning("Path doesn't contain matlabroot!")
                end
        elseif nargin == 5 && strcmp(varargin{1}, "files") && strcmp(varargin{2}, "add") && strcmp(varargin{5}, "--rel")
                % Add a new file entry (relative path) via --rel flag
                if exist(varargin{3}, "file") == 2
                    curPath = pwd;
                    if contains(curPath, matlabroot)
                        curPath = replace(curPath, matlabroot, "<$matlabroot$>");
                        files(varargin{4}) = fullfile(string(curPath), varargin{3});
                    else
                        warning("Path doesn't contain matlabroot!")
                    end
                else
                    warning("Requested file is not in the current path.")
                end
        elseif nargin == 3 && strcmp(varargin{1}, "hist") && strcmp(varargin{2}, "go")
            % Jump to the directory with the user requested index
            history = jump2directory(history, history(str2double(varargin{3})).destination);
        elseif nargin == 3 &&  strcmp(varargin{1}, "book")
            switch varargin{2}
                case "go"
                    if contains(bookmarks(varargin{3}), "<$matlabroot$>")
                        % Convert relative matlabroot to an absolute path
                        pth = resolvePath(bookmarks(varargin{3}));
                    else
                        pth = bookmarks(varargin{3});
                    end
                    % Jump to the directory after the conversion
                    history = jump2directory(history, pth);
                case "add"
                    % Add a new bookmark (absolute path)
                    bookmarks(varargin{3}) = string(pwd);
                case "$add"
                    % Add a new bookmark (relative path)
                    if contains(pwd, matlabroot)
                        curPath = pwd;
                        curPath = erase(curPath, matlabroot);
                        bookmarks(varargin{3}) = string(fullfile("<$matlabroot$>", curPath));
                    else
                        warning("Path doesn't contain matlabroot!")
                    end
                case {"remove", "rm"}
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

function absPath = resolvePath(pth)
    if contains(pth, "<$matlabroot$>")
        absPath = fullfile(replace(pth, "<$matlabroot$>", matlabroot));
    end
end

function showFiles(files)
    if isConfigured(files)
        fprintf('\n');
        disp(entries(files))
        fprintf('\n');
    end
end

function showBookmarks(bookmarks)
    % Create and show bookmarks table
    if isConfigured(bookmarks)
        fprintf('\n');
        disp(entries(bookmarks))
        fprintf('\n');
    end
end

function showHistory(history)
    % Create and show history table
    history_tmp = arrayfun(@(x,y) setfield(x,'item',y), rmfield(history,"source"), 1:numel(history));
    history_tmp = rmfield(history_tmp, 'cursor');
    history_tmp = orderfields(history_tmp, {'item','destination','last_accessed'});
    fprintf('\n');
    disp(struct2table(history_tmp));
    disp(join(["Cursor: ", history(1).cursor],''))
    fprintf('\n');
end

function history = jump2directory(history, target)
    maxHist = 1000; % maximum history size
    if numel(history) > maxHist
        idx = 1;
    else
        idx = numel(history) + 1;
    end

    % Log the source
    history(idx).source = string(pwd);
    
    % cd into the destination
    cd(target)
    
    % Log the destination
    history(idx).destination = string(pwd);
    history(idx).last_accessed = string(datetime("now"));
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
        '      Change directory to <directory> and log it in history.\n\n' ...
        'Quick navigation:\n' ...
        '  sd back | b | -\n' ...
        '      Jump back one step (previous source folder).\n' ...
        '  sd fwd  | f\n' ...
        '      Jump forward one step.\n' ...
        '  sd back/\n' ...
        '      Change to a folder literally named "back" (trailing slash).\n\n' ...
        'Go shortcuts:\n' ...
        '  sd go matlabroot | root\n' ...
        '      Jump to MATLAB root.\n' ...
        '  sd go back | b\n' ...
        '      Alias for sd back.\n' ...
        '  sd go fwd  | f\n' ...
        '      Alias for sd fwd.\n\n' ...
        'Bookmarks:\n' ...
        '  sd book\n' ...
        '      Display bookmarks (same as sd book show).\n' ...
        '  sd book <name>\n' ...
        '      Jump to bookmark <name> (same as sd book go <name>).\n' ...
        '  sd book add <name>\n' ...
        '      Add bookmark <name> for the current folder (absolute path).\n' ...
        '  sd book add <name> --rel\n' ...
        '      Add bookmark <name> for the current folder (relative to matlabroot).\n' ...
        '  sd book $add <name>\n' ...
        '      Alias for sd book add <name> --rel.\n' ...
        '  sd book remove | rm <name>\n' ...
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
        '  sd hist\n' ...
        '      Display history (same as sd hist show).\n' ...
        '  sd hist <index>\n' ...
        '      Jump to history entry <index> (same as sd hist go <index>).\n' ...
        '  sd hist clear\n' ...
        '      Clear history (reinitialize).\n' ...
        '  sd hist go <index>\n' ...
        '      Jump to history entry <index>.\n\n' ...
        'Files:\n' ...
        '  sd files\n' ...
        '      Display file entries (same as sd files show).\n' ...
        '  sd files <alias>\n' ...
        '      Open file <alias> in the editor (same as sd files open <alias>).\n' ...
        '  sd files clear\n' ...
        '      Clear file entries.\n' ...
        '  sd files add <filename> <alias>\n' ...
        '      Add a file entry for <filename> in the current folder (absolute path).\n' ...
        '  sd files add <filename> <alias> --rel\n' ...
        '      Add a file entry for <filename> (relative to matlabroot).\n' ...
        '  sd files $add <filename> <alias>\n' ...
        '      Alias for sd files add <filename> <alias> --rel.\n' ...
        '  sd files remove | rm <alias>\n' ...
        '      Remove file entry <alias>.\n' ...
        '  sd files open | go <alias>\n' ...
        '      Open file entry <alias> in the editor.\n\n' ...
        'Notes:\n' ...
        '  - Bookmarks, history, and files are stored in preferences under group "surfdirectory".\n' ...
        '  - Relative paths use the reserved token "<$matlabroot$>".\n\n' ...
        ]);
end
