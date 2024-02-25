#!/bin/bash

gitReset()
{
    # Reset git
    local result=$(sudo -u $sudo_user_name rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    local result=$(createFolders "loud" $sudo_user_name "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"
    cd "$script_dir"
    checkSuccess "Going into the install folder"
    local result=$(sudo -u $sudo_user_name git clone "$repo_url" "$script_dir" > /dev/null 2>&1)
    checkSuccess "Clone the Git repository"
}
