#!/bin/bash

gitUntrackFiles()
{
    # Fixing the issue where the git does not use the .gitignore
    cd $script_dir
    sudo git config core.fileMode false
    isSuccessful "Removing configs and logs from git for git changes"
    local result=$(sudo -u $sudo_user_name git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"
}
