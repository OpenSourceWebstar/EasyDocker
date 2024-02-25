#!/bin/bash

copyFolder()
{
    local folder="$1"
    local folder_name=$(basename "$folder")
    local save_dir="$2"
    local user_name="$3"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    local result=$(sudo cp -rf "$folder" "$save_dir")
    checkSuccess "Coping $folder_name to $save_dir"

    local result=$(sudo chown $user_name:$user_name "$save_dir/$folder_name")
    checkSuccess "Updating $folder_name with $user_name ownership"
}
