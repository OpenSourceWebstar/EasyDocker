#!/bin/bash

copyFolders()
{
    local source="$1"
    local save_dir="$2"
    local user_name="$3"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    # Ensure the source path is expanded to a list of subdirectories
    local subdirs=($(find "$source" -mindepth 1 -maxdepth 1 -type d))

    if [ ${#subdirs[@]} -eq 0 ]; then
        echo "No subdirectories found in the source directory: $source"
        return
    fi

    for subdir in "${subdirs[@]}"; do
        local subdir_name=$(basename "$subdir")

        local result=$(sudo cp -rf "$subdir" "$save_dir")
        checkSuccess "Copying $subdir_name to $save_dir"

        local result=$(sudo chown -R $user_name:$user_name "$save_dir/$subdir_name")
        checkSuccess "Updating $subdir_name with $user_name ownership"
    done
}
