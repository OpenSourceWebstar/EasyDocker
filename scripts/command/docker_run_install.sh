#!/bin/bash

dockerCommandRunInstallUser() 
{
    local silent_flag=""
    if [ "$1" == "--silent" ]; then
        silent_flag="$1"
        shift
    fi
    local remote_command="$1"

    # Get the value of PasswordAuthentication from sshd_config
    local result=$(sudo sed -i '/#PasswordAuthentication/d' $sshd_config)
    local passwordAuth=$(grep -i "^PasswordAuthentication" $sshd_config | awk '{print $2}')

    # Keys
    local private_path="${ssh_dir}private/"
    local install_user_key="${CFG_INSTALL_NAME}_sshkey_${CFG_DOCKER_INSTALL_USER}"

    # Run the SSH command using the existing SSH variables
    local output
    if [ "$passwordAuth" == "no" ]; then
        if [ -z "$silent_flag" ]; then
            ssh -i "${private_path}${install_user_key}" -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command"
        else
            ssh -i "${private_path}${install_user_key}" -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command" > /dev/null 2>&1
        fi
    else
        if [ -z "$silent_flag" ]; then
            sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command"
        else
            sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command" > /dev/null 2>&1
        fi
    fi

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        return 0  # Success, command completed without errors
    else
        return 1  # Error, command encountered issues
    fi
}
