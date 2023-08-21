#!/bin/bash

installDockerCompose()
{
    if [[ "$ISCOMP" == *"command not found"* ]]; then
        echo "############################################"
        echo "######     Install Docker-Compose     ######"
        echo "############################################"

        # install docker-compose
        echo ""
        echo "---- $menu_number. Installing Docker-Compose..."
        echo ""
        echo ""
        sleep 2s

        ######################################
        ###     Install Debian / Ubuntu    ###
        ######################################        
        
        if [[ "$OS" == "1" || "$OS" == "2" || "$OS" == "3" ]]; then
            VERSION=$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*\d')
            sudo curl -SL https://github.com/docker/compose/releases/download/$VERSION/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
            #sudo curl -L "https://github.com/docker/compose/releases/download/$(curl https://github.com/docker/compose/releases | grep -m1 '<a href="/docker/compose/releases/download/' | grep -o 'v[0-9:].[0-9].[0-9]')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

            sleep 2
            sudo chmod +x /usr/local/bin/docker-compose
        fi

        ######################################
        ###        Install Arch Linux      ###
        ######################################

        if [[ "$OS" == "4" ]]; then
            sudo pacman -Sy docker-compose --noconfirm > $logs_dir/$docker_log_file 2>&1
        fi


        echo ""

        echo "      - Docker Compose Version is now: " 
        DOCKCOMPV=$(docker-compose --version)
        echo "        "${DOCKCOMPV}
        echo ""
        echo ""
        sleep 3s
    fi
}

installDockerUser()
{
    if [[ "$ISACT" != "active" ]]; then
        if [[ "$DOCK" == [yY] ]]; then
            # add current user to docker group so sudo isn't needed
            echo ""
            echo "  - Attempting to add the currently logged in user to the docker group..."

            sleep 2s
            sudo usermod -aG docker "${USER}" >> $logs_dir/$docker_log_file 2>&1
            echo "  - You'll need to log out and back in to finalize the addition of your user to the docker group."
            echo ""
            echo ""
            sleep 3s
        fi
    fi
}

installDockerNetwork()
{
	# Check if the network already exists
	if ! docker network ls | grep -q "$CFG_NETWORK_NAME"; then
        echo ""
        echo "################################################"
        echo "######      Create a Docker Network    #########"
        echo "################################################"
        echo ""

		echo "Network $CFG_NETWORK_NAME not found, creating now"
		# If the network does not exist, create it with the specified subnet
		docker network create \
			--driver=bridge \
			--subnet=$CFG_NETWORK_SUBNET \
			--ip-range=$CFG_NETWORK_SUBNET \
			--gateway=${CFG_NETWORK_SUBNET%.*}.1 \
			--opt com.docker.network.bridge.name=$CFG_NETWORK_NAME \
			$CFG_NETWORK_NAME
	fi
}

installDockerCheck()
{
    ##########################################
    #### Test if Docker Service is Running ###
    ##########################################
    ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
    if [[ "$ISACT" != "active" ]]; then
        isNotice "Checking Docker service status. Waiting if not found."
        while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
            sudo systemctl start docker >> $logs_dir/$docker_log_file 2>&1
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
}
