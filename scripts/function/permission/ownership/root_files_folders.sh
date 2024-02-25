#!/bin/bash

changeRootOwnedFilesAndFolders()
{
    local dir_to_change="$1"
    local user_name="$2"

    # Check if the directory exists
    if [ ! -d "$dir_to_change" ]; then
        isError "Install directory '$dir_to_change' does not exist."
        return 1
    fi

    # Start the result command in the background
    (sudo find "$dir_to_change" -type f -user root -exec sudo chown "$user_name:$user_name" {} \; ) &

    local start_time=$(date +%s)
    local time_threshold=5

    # Check periodically if the result command is still running
    while ps -p $! > /dev/null; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "$time_threshold" ]; then
            # Display the message
            isNotice "Updating ownership of $dir_to_change"
            isNotice "This may take a while depending on the size/amount of files..."
            break
        fi
        sleep 1
    done
    isSuccessful "Find files owned by root and change ownership"

    local result=$(sudo find "$dir_to_change" -type d -user root -exec sudo chown "$user_name:$user_name" {} \;)
    checkSuccess "Find directories owned by root and change ownership"

    isSuccessful "Updated ownership of root-owned files and directories."
}
