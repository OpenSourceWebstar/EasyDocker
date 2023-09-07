#!/bin/bash

installDockerCompose()
{
    if [[ "$ISCOMP" == *"command not found"* ]]; then
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
        
        if [[ "$OS" == "1" || "$OS" == "2" || "$OS" == "3" ]]; then
            result=$(sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose)
            checkSuccess "Download the official Docker Compose script"

            result=$(sudo chmod +x /usr/local/bin/docker-compose)
            checkSuccess "Make the script executable"

            result=$(docker-compose --version)
            checkSuccess "Verify the installation"
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
    if id "$CFG_DOCKER_INSTALL_USER" &>/dev/null; then
        isSuccessful "User $CFG_DOCKER_INSTALL_USER already exists."
    else
        # If the user doesn't exist, create the user
        result=$(useradd -s /bin/bash -d "/home/$CFG_DOCKER_INSTALL_USER" -m -G sudo "$CFG_DOCKER_INSTALL_USER")
        checkSuccess "Creating $CFG_DOCKER_INSTALL_USER User."
        result=$(echo "$CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_PASS" | chpasswd)
        checkSuccess "Setting password for $CFG_DOCKER_INSTALL_USER User."
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

installDockerRootless()
{
	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
		if grep -q "ROOTLESS" $sysctl; then
			isNotice "Docker Rootless appears to be installed."
        else
            local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")

            result=$(runuser -l "$CFG_DOCKER_INSTALL_USER" -c "cd \$HOME && curl -fsSL https://get.docker.com/rootless | sh -s && cp ~/.bashrc ~/.bashrc.bak")
            checkSuccess "Installing Docker Rootless script"

            # Use runuser for the grep operation
            if ! grep -qF \"# DOCKER ROOTLESS CONFIG FROM .sh SCRIPT\" \"$sshd_config\"; then
                result=$(echo '# DOCKER ROOTLESS CONFIG FROM .sh SCRIPT' >> \"$sshd_config\")
                checkSuccess "Adding rootless header to sshd_config"
                result=$(echo 'export PATH=/home/$CFG_DOCKER_INSTALL_USER/bin:\$PATH' >> \"$sshd_config\")
                checkSuccess "Adding export path to sshd_config"
                result=$(echo 'export DOCKER_HOST=unix:///run/user/$docker_install_user_id/docker.sock' >> \"$sshd_config\")
                checkSuccess "Adding export docker_host path to sshd_config"
                isSuccessful "Added $CFG_DOCKER_INSTALL_USER to sshd_config file"
            fi

            result=$(sudo systemctl disable --now docker.service docker.socket)
            checkSuccess "Disabling Docker service & Socket"

            result=$(runuser -l "$CFG_DOCKER_INSTALL_USER" -c "systemctl --user start docker")
            checkSuccess "Starting Docker for $CFG_DOCKER_INSTALL_USER"

            result=$(runuser -l "$CFG_DOCKER_INSTALL_USER" -c "systemctl --user enable docker")
            checkSuccess "Enabling Docker for $CFG_DOCKER_INSTALL_USER"

            result=$(sudo loginctl enable-linger $CFG_DOCKER_INSTALL_USER)
            checkSuccess "Adding automatic start (linger)"

            result=$(sudo cp $sysctl $sysctl.bak)
            checkSuccess "Backing up sysctl file"
            
            # Use runuser for the grep operation
            if ! runuser -l "$CFG_DOCKER_INSTALL_USER" -c "grep -qF \"# DOCKER ROOTLESS CONFIG TO MAKE IT WORK WITH SSL LETSENCRYPT\" \"$sysctl\""; then
                result=$(runuser -l "$CFG_DOCKER_INSTALL_USER" -c "echo '# DOCKER ROOTLESS CONFIG TO MAKE IT WORK WITH SSL LETSENCRYPT' >> \"$sysctl\"")
                checkSuccess "Adding rootless header to sysctl"
                result=$(runuser -l "$CFG_DOCKER_INSTALL_USER" -c "echo 'net.ipv4.ip_unprivileged_port_start=0' >> \"$sysctl\"")
                checkSuccess "Adding ip_unprivileged_port_start to sysctl"
                result=$(runuser -l "$CFG_DOCKER_INSTALL_USER" -c "echo 'kernel.unprivileged_userns_clone=1' >> \"$sysctl\"")
                checkSuccess "Adding unprivileged_userns_clone to sysctl"
                isSuccess "Updated the sysctl to with Docker Rootless configuration"
            fi

            result=$(sudo sysctl --system)
            checkSuccess "Applying changes to sysctl"
            result=$(sudo reboot)
            checkSuccess "Restarting server... please run 'easydocker' again after the server is back online"
        fi
    fi
}