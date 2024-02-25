#!/bin/bash

changeRootOwnedFile()
{
    local file_full="$1" # Includes path
    local file_name=$(basename "$file")
    local user_name="$2"

    # Check if the file exists
    if [ ! -f "$file_full" ]; then
        if [[ $file_full == "$docker_dir/$db_file" ]]; then
            isNotice "$db_file is not yet created."
        else
            isError "File '$file_full' does not exist."
        fi
        return 1
    fi

    local result=$(sudo sudo chown "$user_name:$user_name" "$file_full")
    checkSuccess "Updating $file_name to be owned by $user_name"
}
