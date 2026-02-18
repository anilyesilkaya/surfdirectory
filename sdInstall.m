function sdInstall

    % --- Moving the main script to the user path ---
    ROOT_FOLDER = "/home/ayesilka/Downloads/surfdir-matlab-main";
    copyfile(fullfile(ROOT_FOLDER, "sd.m"), userpath)

    % --- Create the initial function signatures with the bult-in functions ---
    updateFunctionSignatures()
    if ~exist(fullfile(userpath, "resources"), "dir")
        mkdir(fullfile(userpath, "resources"))
    end
    copyfile(fullfile(ROOT_FOLDER, "resources", "functionSignatures.json"), fullfile(userpath, "resources"))
end
