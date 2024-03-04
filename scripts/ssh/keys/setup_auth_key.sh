#!/bin/bash

setupSSHAuthorizedKeys()
{
    local username="$1"
    local public_key_full="$2"

    if [[ "$username" == "root" ]]; then
        local ssh_path="/root/.ssh" 
    else
        local ssh_path="/home/$username/.ssh" 
    fi

    # Check if the directory exists; if not, create it
    if [ ! -d "$ssh_path" ]; then
        local result=$(createFolders "loud" $username $ssh_path)
        checkSuccess "Creating $(basename "$private_key_path") folder"
        result=$(sudo chmod 700 $ssh_path)
        checkSuccess "Updating permissions for $ssh_path"
    else
        result=$(sudo chmod 700 $ssh_path)
        checkSuccess "Updating permissions for $ssh_path"
    fi

    if [ -f "${ssh_path}/authorized_keys" ]; then
        result=$(sudo rm ${ssh_path}/authorized_keys)
        checkSuccess "Deleted old authorized_keys file for user $username"
    fi

    result=$(sudo cp "$public_key_full" "${ssh_path}/authorized_keys")
    checkSuccess "Adding $(basename $public_key_full) to the Authorized_keys file for user $username"

    result=$(sudo chmod 600 ${ssh_path}/authorized_keys)
    checkSuccess "Updating permissions for ${username}'s authorized_keys file."

    updateFileOwnership "${ssh_path}/authorized_keys" $username $username

    result=$(sudo systemctl reload ssh)
    checkSuccess "Reloading SSH service"
}
