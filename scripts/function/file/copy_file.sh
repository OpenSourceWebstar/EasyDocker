#!/bin/bash

copyFile()
{
    local silent_flag="$1"
    local file="$2"
    local file_name=$(basename "$file")
    local save_dir="$3"
    local save_dir_file=$(basename "$save_dir")
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')
    local user_name="$4" 
    local flags="$5"

    if [[ $flags == "overwrite" ]]; then
        flags_full="-f"
    fi
    
    if [ "$silent_flag" == "loud" ]; then
        local result=$(sudo cp $flags_full "$file" "$save_dir")
        checkSuccess "Copying $file_name to $save_dir"
    elif [ "$silent_flag" == "silent" ]; then
        local result=$(sudo cp $flags_full "$file" "$save_dir")
    fi

    if [ "$silent_flag" == "loud" ]; then
        local result=$(sudo chown $user_name:$user_name "$save_dir")
        checkSuccess "Updating $save_dir_file with $user_name ownership"
    elif [ "$silent_flag" == "silent" ]; then
        local result=$(sudo chown $user_name:$user_name "$save_dir")
    fi
}
