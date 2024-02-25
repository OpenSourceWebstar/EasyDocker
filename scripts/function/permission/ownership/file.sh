#!/bin/bash

updateFileOwnership() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local clean_dir=$(echo "$file" | sed 's#//*#/#g')
    local user_name_1="$2"
    local user_name_2="$3"

    local result=$(sudo chown $user_name_1:$user_name_2 "$file")
    checkSuccess "Updating $file_name with $user_name ownership"
}
