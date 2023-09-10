#!/bin/bash

installDebianUbuntu()
{
    if [[ "$OS" == [123] ]]; then
        if checkIfUpdateShouldRun; then
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
            result=$(sudo apt update > /dev/null)
            checkSuccess "Running application update"
            installed_apps="apt install curl wget git zip htop sqlite3 pv sshpass rsync acl p7zip*"
            result=$(sudo $installed_apps -y > /dev/null)
            checkSuccess "Installing system applications"
        else
            isNotice "System Updates already ran within the last ${CFG_UPDATER_CHECK} minutes, skipping..."
        fi
    fi
}

installArch()
{
    if [[ "$OS" == "4" ]]; then
        read -rp "Do you want to install system updates prior to installing Docker-CE? (y/n): " UPDARCH
        if [[ "$UPDARCH" == [yY] ]]; then
            isNotice "Installing System Updates... this may take a while...be patient."
            
            (sudo pacman -Syu --noconfirm) > $logs_dir/$docker_log_file 2>&1 &
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
        else
            isNotice "Skipping system update..."
        fi

        isNotice "Installing Prerequisite Packages..."

        sudo pacman -Sy git curl wget --noconfirm | sudo tee -a "$logs_dir/$docker_log_file" 2>&1

        if [[ "$ISACT" != "active" ]]; then
            isNotice "Installing Docker-CE (Community Edition)..."

            sudo pacman -Sy docker --noconfirm | sudo tee -a "$logs_dir/$docker_log_file" 2>&1

            echo "- docker-ce version is now:"
            DOCKERV=$(docker -v)
            echo ""${DOCKERV}
        fi
    fi
}