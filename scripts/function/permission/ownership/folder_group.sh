#!/bin/bash

changeUserGroupOnFolder()
{
    local source_user="$1"
    local target_user="$2"
    local directory="$3"

    # Check if the source user exists
    id "$source_user" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Source user '$source_user' does not exist."
        return 1
    fi

    # Check if the target user exists
    id "$target_user" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Target user '$target_user' does not exist."
        return 1
    fi

    # Check if the directory exists
    if [ ! -d "$directory" ]; then
        isError "Directory '$directory' not found."
        return 1
    fi

    local result=$(find "$directory" -user "$source_user" -exec chown "$target_user" {} +)
    checkSuccess "Updating $directory user to be $target_user... This may take a while..."

    # Check if the source group exists
    local source_group=$(id -g -n "$source_user")
    if [ $? -ne 0 ]; then
        isError "Unable to determine source group for user '$source_user'."
        return 1
    fi

    # Check if the target group exists
    local target_group=$(id -g -n "$target_user")
    if [ $? -ne 0 ]; then
        isError "Unable to determine target group for user '$target_user'."
        return 1
    fi

    local result=$(find "$directory" -group "$source_group" -exec chgrp "$target_group" {} +)
    checkSuccess "Updating $directory group to be $target_user... This may take a while..."
}
