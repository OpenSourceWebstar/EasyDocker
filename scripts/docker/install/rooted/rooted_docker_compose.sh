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
        
        if [[ "$OS_TYPE" == "Ubuntu" || "$OS_TYPE" == "Debian" ]]; then
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

        if [[ "$OS_TYPE" == "Arch" ]]; then
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
