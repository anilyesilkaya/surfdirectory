function updateFunctionSignatures(~)

    try
        thisFile = mfilename("fullpath");
        [thisFolder, ~, ~] = fileparts(thisFile);

        resourcesFolder = fullfile(thisFolder, "resources");
        if ~isfolder(resourcesFolder)
            mkdir(resourcesFolder);
        end

        sigFile = fullfile(resourcesFolder, "functionSignatures.json");

        %% ---------- Option 1: sd <folder> -----------------------------
        paramFolder = struct();
        paramFolder.name = "path";
        paramFolder.kind = "ordered";
        paramFolder.type = {{"folder"}};

        %% ---------- Option 2: sd go <target> --------------------------
        paramGo = struct();
        paramGo.name = "cmd1";
        paramGo.kind = "ordered";
        paramGo.type = {"choices={'go'}"};

        paramGoTarget = struct();
        paramGoTarget.name = "cmd2";
        paramGoTarget.kind = "ordered";
        paramGoTarget.type = {"choices={'matlabroot','root','back','b','fwd','f'}"};

        groupGo = {paramGo, paramGoTarget};

        %% ---------- Option 3: sd book <subcmd> [arg] ------------------
        paramBook = struct();
        paramBook.name = "cmd1";
        paramBook.kind = "ordered";
        paramBook.type = {"choices={'book'}"};

        % book show|export|load|clear (2-arg form)
        paramBook2_simple = struct();
        paramBook2_simple.name = "cmd2";
        paramBook2_simple.kind = "ordered";
        paramBook2_simple.type = {"choices={'show','export','load','clear'}"};
        groupBook_simple = {paramBook, paramBook2_simple};

        % book add|$add|remove|go <name> (3-arg form)
        paramBook2_action = struct();
        paramBook2_action.name = "cmd2";
        paramBook2_action.kind = "ordered";
        paramBook2_action.type = {"choices={'add','$add','remove','go'}"};

        paramBookName = struct();
        paramBookName.name = "name";
        paramBookName.kind = "ordered";
        paramBookName.type = {{"char"}};

        groupBook_action = {paramBook, paramBook2_action, paramBookName};

        %% ---------- Option 4: sd hist <subcmd> [arg] ------------------
        paramHist = struct();
        paramHist.name = "cmd1";
        paramHist.kind = "ordered";
        paramHist.type = {"choices={'hist'}"};

        % hist show|clear (2-arg form)
        paramHist2_simple = struct();
        paramHist2_simple.name = "cmd2";
        paramHist2_simple.kind = "ordered";
        paramHist2_simple.type = {"choices={'show','clear'}"};
        groupHist_simple = {paramHist, paramHist2_simple};

        % hist go <index> (3-arg form)
        paramHist2_go = struct();
        paramHist2_go.name = "cmd2";
        paramHist2_go.kind = "ordered";
        paramHist2_go.type = {"choices={'go'}"};

        paramHistIndex = struct();
        paramHistIndex.name = "index";
        paramHistIndex.kind = "ordered";
        paramHistIndex.type = {{"char"}};   % user types 3, "3", etc.

        groupHist_go = {paramHist, paramHist2_go, paramHistIndex};

        %% ---------- Option 5: sd files <subcmd> [arg] -----------------
        paramFiles = struct();
        paramFiles.name = "cmd1";
        paramFiles.kind = "ordered";
        paramFiles.type = {"choices={'files'}"};

        % files show|clear (2-arg form)
        paramFiles2_simple = struct();
        paramFiles2_simple.name = "cmd2";
        paramFiles2_simple.kind = "ordered";
        paramFiles2_simple.type = {"choices={'show','clear'}"};
        groupFiles_simple = {paramFiles, paramFiles2_simple};

        % files open|remove <alias> (3-arg form)
        paramFiles2_idx = struct();
        paramFiles2_idx.name = "cmd2";
        paramFiles2_idx.kind = "ordered";
        paramFiles2_idx.type = {"choices={'open','remove'}"};

        paramFilesAlias = struct();
        paramFilesAlias.name = "alias";
        paramFilesAlias.kind = "ordered";
        paramFilesAlias.type = {{"char"}};   % dictionary key / alias

        groupFiles_idx = {paramFiles, paramFiles2_idx, paramFilesAlias};

        %% ---------- Option 6: sd files add|$add <filename> <alias> ----
        paramFiles2_add = struct();
        paramFiles2_add.name = "cmd2";
        paramFiles2_add.kind = "ordered";
        paramFiles2_add.type = {"choices={'add','$add'}"};

        paramFilesFilename = struct();
        paramFilesFilename.name = "filename";
        paramFilesFilename.kind = "ordered";
        paramFilesFilename.type = {"file=*.*"};

        paramFilesAlias2 = struct();
        paramFilesAlias2.name = "alias";
        paramFilesAlias2.kind = "ordered";
        paramFilesAlias2.type = {{"char"}};

        groupFiles_add4 = {paramFiles, paramFiles2_add, paramFilesFilename, paramFilesAlias2};

        %% ---------- Mutually exclusive top-level shapes ---------------
        inputStruct = struct();
        inputStruct.mutuallyExclusiveGroup = { ...
            {paramFolder}, ...
            groupGo, ...
            groupBook_simple, ...
            groupBook_action, ...
            groupHist_simple, ...
            groupHist_go, ...
            groupFiles_simple, ...
            groupFiles_idx, ...
            groupFiles_add4 ...
        };

        sdStruct = struct();
        sdStruct.inputs = {inputStruct};

        root = containers.Map();
        root("_schemaVersion") = "1.0.0";
        root("sd") = sdStruct;

        txt = jsonencode(root, "PrettyPrint", true);

        fid = fopen(sigFile, "w");
        if fid < 0
            return;
        end
        cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
        fwrite(fid, txt, "char");

    catch
        % swallow errors (keeps startup robust)
    end
end