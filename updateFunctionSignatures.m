function updateFunctionSignatures(~)
    % Update functionSignatures.json for sd.
    %
    % Desired JSON:
    %
    % {
    %   "_schemaVersion": "1.0.0",
    %   "sd": {
    %     "inputs": [
    %       {
    %         "mutuallyExclusiveGroup": [
    %           [
    %             {
    %               "name": "path",
    %               "kind": "positional",
    %               "type": [
    %                 ["folder"],
    %                 ["char"]
    %               ]
    %             }
    %           ]
    %         ]
    %       }
    %     ]
    %   }
    % }
    
    try
        % Where is sd.m?
        thisFile = mfilename('fullpath');
        [thisFolder, ~, ~] = fileparts(thisFile);
    
        % Ensure resources/ exists next to sd.m
        resourcesFolder = fullfile(thisFolder, "resources");
        if ~isfolder(resourcesFolder)
            mkdir(resourcesFolder);
        end
    
        sigFile = fullfile(resourcesFolder, "functionSignatures.json");
    
        % ---- Build the sd structure ----
    
        % Parameter definition: {"name":"path","kind":"positional","type":[["folder"],["char"]]}
        param = struct();
        param.name = "path";
        param.kind = "ordered";
        % type: [["folder"], ["char"]]
        param.type = {{"folder"}, {"char"}};
    
        % mutuallyExclusiveGroup: [ [ {param} ] ]
        group = {param};                    % [ {param} ]
        mutuallyExclusiveGroup = {group};   % [ [ {param} ] ]
    
        % inputs: [ { "mutuallyExclusiveGroup": ... } ]
        inputStruct = struct();
        inputStruct.mutuallyExclusiveGroup = mutuallyExclusiveGroup;
    
        sdStruct = struct();
        sdStruct.inputs = {inputStruct};    % cell array → JSON array
    
        % ---- Build root as a containers.Map so we can use "_schemaVersion" ----
        root = containers.Map();
        root('_schemaVersion') = '1.0.0';
        root('sd')             = sdStruct;
    
        txt = jsonencode(root, "PrettyPrint", true);
    
        % ---- Write the file ----
        fid = fopen(sigFile, "w");
        if fid < 0
            return;
        end
        cleaner = onCleanup(@() fclose(fid));
        fwrite(fid, txt, "char");
    
    catch
        % Best effort only; sd still works if this fails.
    end
end

