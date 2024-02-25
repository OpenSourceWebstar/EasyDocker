#!/bin/bash

createFolders()
{
    local silent_flag="$1"
    local user_name="$2"

    for dir_path in "${@:3}"; do
        local folder_name=$(basename "$dir_path")
        local clean_dir=$(echo "$dir_path" | sed 's#//*#/#g')

        if [ ! -d "$dir_path" ]; then
            local result=$(sudo mkdir -p "$dir_path")
            if [ -z "$silent_flag" ]; then
                checkSuccess "Creating $folder_name directory"
            fi
        else
            if [ -z "$silent_flag" ]; then
                isNotice "$folder_name directory already exists"
            fi
        fi

        local result=$(sudo chown $user_name:$user_name "$dir_path")
        if [ "$silent_flag" == "silent" ]; then
            checkSuccess "Updating $folder_name with $user_name ownership"
        fi
    done
}
