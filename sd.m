function sd(varargin)
    % sd : help
    % sd .directory/: jumps into that directory
    % sd matlabroot or sd -root: jumps into matlabroot
    % sd -: goes back one step in time
    % sd -h: jump history
    prefGroup = "surfdirectory";
    prefName  = "bookmarks";

    % Ensure preference exists
    if ~ispref(prefGroup, prefName)
        bookmarks = struct();
        setpref(prefGroup, prefName, bookmarks);
    else
        bookmarks = getpref(prefGroup, prefName);
    end

    % Input handling
    if nargin == 0
        showHelp(bookmarks);
    elseif nargin == 1
        var = varargin{1};
        if strcmp(var, "matlabroot") || strcmp(var, "-root")
            sd(matlabroot)
        elseif strcmp(var, "-")
            % Handle the case for going back in history
        else
            assert((isa(var, "string") || isa(var,"char")), "Input must be a char or string of the relative path")
            cd(var)
        end
    end
end

% Local helpers

function showHelp(bookmarks)
    fprintf("\n------------------------------------------------\n");
    fprintf("surfdirectory (sd)\n");
    fprintf("------------------------------------------------\n");
    fprintf("Usage:\n");
    fprintf("  sd                 - Show this help and list bookmarks\n");
    fprintf("  sd name            - cd to bookmark 'name'\n");
    fprintf("  sd -add name       - Add bookmark for current folder\n");
    fprintf("  sd -add name path  - Add bookmark for 'path'\n");
    fprintf("  sd -list           - List bookmarks\n");
    fprintf("  sd -remove name    - Remove bookmark 'name'\n\n");
    
    % localListBookmarks(bookmarks);
end