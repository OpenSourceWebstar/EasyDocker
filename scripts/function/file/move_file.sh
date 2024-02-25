#!/bin/bash

moveFile() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local save_dir="$2"
    local save_dir_file=$(basename "$save_dir")
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    if [ -e "$file" ]; then
        local result=$(sudo mv "$file" "$save_dir")
        checkSuccess "Moving $file_name to $save_dir"

        if [[ $clean_dir != *"$containers_dir"* ]]; then
            local result=$(sudo chown $sudo_user_name:$sudo_user_name "$save_dir")
            checkSuccess "Updating $save_dir_file with $sudo_user_name ownership"
        fi
    else
        isNotice "Source file does not exist: $file"
    fi
}
