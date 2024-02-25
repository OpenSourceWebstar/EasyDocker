#!/bin/bash

copyFiles()
{
    local silent_flag="$1"
    local source="$2"
    local save_dir="$3"
    local user_name="$4"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    # Ensure the source path is expanded to a list of files
    local files=($(sudo find "$source" -type f))

    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found in the source directory: $source"
        return
    fi

    for file in "${files[@]}"; do
        local file_name=$(basename "$file")

        if [ "$silent_flag" == "loud" ]; then
            local result=$(sudo cp -f "$file" "$save_dir")
            checkSuccess "Copying $file_name to $save_dir"
        elif [ "$silent_flag" == "silent" ]; then
            local result=$(sudo cp -f "$file" "$save_dir")
        fi

        if [ "$silent_flag" == "loud" ]; then
            local result=$(sudo chown $user_name:$user_name "$save_dir/$file_name")
            checkSuccess "Updating $file_name with $user_name ownership"
        elif [ "$silent_flag" == "silent" ]; then
            local result=$(sudo chown $user_name:$user_name "$save_dir/$file_name")
        fi
    done
}
