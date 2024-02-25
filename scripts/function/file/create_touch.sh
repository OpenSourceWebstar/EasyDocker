#!/bin/bash

createTouch() 
{
    local file="$1"
    local user_name="$2"
    local file_name=$(basename "$file")
    local file_dir=$(dirname "$file")
    local clean_dir=$(echo "$file" | sed 's#//*#/#g')

    local result=$(sudo touch "$clean_dir")
    checkSuccess "Touching $file_name to $file_dir"

    local result=$(sudo chown $user_name:$user_name "$file")
    checkSuccess "Updating $file_name with $user_name ownership"
}
