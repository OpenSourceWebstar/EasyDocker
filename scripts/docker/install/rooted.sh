#!/bin/bash

installDockerRootedCompose()
{
    if [[ "$ISCOMP" == *"command not found"* ]]; then
        echo ""
        echo "############################################"
        echo "######     Install Docker-Compose     ######"
        echo "############################################"

        # install docker-compose
        ((menu_number++))
        echo ""
        echo "---- $menu_number. Installing Docker-Compose..."
        echo ""
        echo ""
        sleep 2s

        ######################################
        ###     Install Debian / Ubuntu    ###
        ######################################        
        
        if [[ "$OS" == [1234567] ]]; then
            local result=$(sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" -o /usr/local/bin/docker-compose)
            checkSuccess "Download the official Docker Compose script"

            local result=$(sudo chmod +x /usr/local/bin/docker-compose)
            checkSuccess "Make the script executable"

            local result=$(docker-compose --version)
            checkSuccess "Verify the installation"
        fi

        ######################################
        ###        Install Arch Linux      ###
        ######################################

        if [[ "$OS" == "4" ]]; then
            pacman -Sy docker-compose --noconfirm > $logs_dir/$docker_log_file 2>&1
        fi

        echo ""

        echo "      - Docker Compose Version is now: " 
        DOCKCOMPV=$(docker-compose --version)
        echo "        "${DOCKCOMPV}
        echo ""
        echo ""
		menu_number=0
        sleep 1s
    fi
}

installDockerRootedCheck()
{
    ##########################################
    #### Test if Docker Service is Running ###
    ##########################################
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
        if [[ "$ISACT" != "active" ]]; then
            isNotice "Checking Docker service status. Waiting if not found."
            while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
                sudo systemctl start docker | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
                sleep 10s &
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
                ISACT=`sudo systemctl is-active docker`
                let X=X+1
                echo "$X"
            done
        fi
    fi
}

installDockerRooted()
{
    # Check if Docker is already installed
    if [[ "$OS" == [1234567] ]]; then
        if command -v docker &> /dev/null; then
            isSuccessful "Docker is already installed."
        else
            local result=$(sudo curl -fsSL https://get.docker.com | sh )
            checkSuccess "Downloading & Installing Docker"

            dockerServiceStart;
        fi

        isSuccessful "Docker has been installed and configured."
    fi
}