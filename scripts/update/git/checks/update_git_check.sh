#!/bin/bash

gitCheckForUpdate()
{
    # Check the status of the local repository
    cd "$script_dir"
    sudo -u $sudo_user_name git fetch > /dev/null 2>&1
    if sudo -u $sudo_user_name git status | grep -q "Your branch is ahead"; then
        isSuccessful "The repository is up to date...continuing..."
    elif sudo -u $sudo_user_name git status | grep -q "Your branch is up to date with"; then
        isSuccessful "The repository is up to date...continuing..."
    else
        isNotice "Updates found."
        if [[ $CFG_REQUIREMENT_AUTO_UPDATES == "true" ]]; then
            gitFolderResetAndBackup;
        else
            while true; do
                isQuestion "Do you want to update EasyDocker now? (y/n): "
                read -rp "" acceptupdates
                if [[ "$acceptupdates" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done
            if [[ $acceptupdates == [yY] ]]; then
                gitFolderResetAndBackup;
            fi
        fi
    fi
}
