function sdInstall

    % --- Moving the main script to the user path ---
    ROOT_FOLDER = "C:\Users\ayesilka\GitHub\sd\surfdir-matlab\";
    copyfile(ROOT_FOLDER + "sd.m", userpath)

    % --- Create the initial function signatures with the bult-in functions ---
    updateFunctionSignatures()
    if ~exist(userpath + "\resources\","dir")
        mkdir(userpath + "\resources\")
    end
    copyfile(ROOT_FOLDER + "resources\functionSignatures.json", userpath + "\resources\")
end