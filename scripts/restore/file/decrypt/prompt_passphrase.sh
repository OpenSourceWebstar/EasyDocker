#!/bin/bash

# Function to prompt for passphrase
prompt_passphrase() 
{
    isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
    read -s -r passphrase

    if [ "$passphrase" = "x" ]; then
        isNotice "Exiting..."
        exit 1
    fi
}
