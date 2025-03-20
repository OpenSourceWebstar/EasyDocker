#!/bin/bash

installArch()
{
    if [[ "$OS_TYPE" == "Arch" ]]; then
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