#!/bin/bash

fixFolderPermissions()
{
    local silent_flag="$1"
    local app_name="$2"

    local result=$(sudo chmod +x "$docker_dir" > /dev/null 2>&1)
    if [ "$silent_flag" == "loud" ]; then
        checkSuccess "Updating $docker_dir with execute permissions."
    fi

    local result=$(sudo chmod +x "$containers_dir" > /dev/null 2>&1)
    if [ "$silent_flag" == "loud" ]; then
        checkSuccess "Updating $containers_dir with execute permissions."
    fi
    
    local result=$(sudo find "$script_dir" "$ssl_dir" "$ssh_dir" "$backup_dir" "$restore_dir" "$migrate_dir" -maxdepth 2 -type d -exec sudo chmod +x {} \;)
    if [ "$silent_flag" == "loud" ]; then
        checkSuccess "Adding execute permissions for $docker_install_user user"
    fi

    # Install user related
    local result=$(sudo chown $docker_install_user:$docker_install_user "$containers_dir" > /dev/null 2>&1)
    if [ "$silent_flag" == "loud" ]; then
        checkSuccess "Updating $containers_dir with $docker_install_user ownership"
    fi
}
