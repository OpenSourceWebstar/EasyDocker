#!/bin/bash

installDebianUbuntu()
{
    if [[ "$OS" == [1234567] ]]; then
        if checkIfOSUpdateShouldRun; then
            isNotice "Installing System Updates... this may take a while...be patient."
            if [[ "$OS" == "1" ]]; then
                export DEBIAN_FRONTEND="noninteractive"
            fi
            (apt update && apt install sudo -y && apt-get autoclean) > $logs_dir/$docker_log_file 2>&1 &
            ## Show a spinner for activity progress
            pid=$! # Process Id of the previous running command
            spin='-\|/'
            i=0
            while kill -0 $pid 2>/dev/null
            do
                i=$(( (i+1) %4 ))
                printf "\r${spin:$i:1}"
                sleep .1
            done
            printf "\r"

            isNotice "Installing Prerequisite Packages..."
            local result=$(sudo apt update 2>/dev/null)
            checkSuccess "Running application update"
            installed_apps="apt install curl dialog wget git zip htop sqlite3 pv sshpass rsync acl apache2-utils p7zip*"
            local result=$(sudo $installed_apps -y 2>/dev/null)
            checkSuccess "Installing system applications"
        else
            isNotice "System Updates already ran within the last ${CFG_UPDATER_CHECK} minutes, skipping..."
        fi
    fi
}
