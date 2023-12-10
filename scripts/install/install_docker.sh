#!/bin/bash

installDocker()
{
    # Check if Docker is already installed
    if [[ "$OS" == "1" || "$OS" == "2" || "$OS" == "3" ]]; then
        if command -v docker &> /dev/null; then
            isSuccessful "Docker is already installed."
        else
            local result=$(sudo curl -fsSL https://get.docker.com | sh )
            checkSuccess "Downloading & Installing Docker"

            if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
                local result=$(sudo -u $sudo_user_name systemctl start docker)
                checkSuccess "Starting Docker Service"

                local result=$(sudo -u $sudo_user_name systemctl enable docker)
                checkSuccess "Enabling Docker Service"

                local result=$(sudo -u $sudo_user_name usermod -aG docker $USER)
                checkSuccess "Adding user to 'docker' group"
            fi
        fi

        isSuccessful "Docker has been installed and configured."
    fi
}

installDockerCompose()
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
            sudo -u $sudo_user_name pacman -Sy docker-compose --noconfirm > $logs_dir/$docker_log_file 2>&1
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

installDockerUser()
{   
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        if id "$CFG_DOCKER_INSTALL_USER" &>/dev/null; then
            isSuccessful "User $CFG_DOCKER_INSTALL_USER already exists."
        else
            # If the user doesn't exist, create the user
            local result=$(sudo useradd -s /bin/bash -d "/home/$CFG_DOCKER_INSTALL_USER" -m -G sudo "$CFG_DOCKER_INSTALL_USER")
            checkSuccess "Creating $CFG_DOCKER_INSTALL_USER User."
            updateDockerInstallPassword;
        fi
    fi
}

installDockerNetwork()
{
	# Check if the network already exists
    if ! runCommandForDockerInstallUser "docker network ls | grep -q \"$CFG_NETWORK_NAME\""; then
        echo ""
        echo "################################################"
        echo "######      Create a Docker Network    #########"
        echo "################################################"
        echo ""

		isNotice "Network $CFG_NETWORK_NAME not found, creating now"
		# If the network does not exist, create it with the specified subnet
network_create=$(cat <<EOF
docker network create \
  --driver=bridge \
  --subnet=$CFG_NETWORK_SUBNET \
  --ip-range=$CFG_NETWORK_SUBNET \
  --gateway=${CFG_NETWORK_SUBNET%.*}.1 \
  --opt com.docker.network.bridge.name=$CFG_NETWORK_NAME \
  $CFG_NETWORK_NAME
EOF
)
        local result=$(runCommandForDockerInstallUser "$network_create")
        checkSuccess "Creating docker network"
	fi
}

installDockerCheck()
{
    ##########################################
    #### Test if Docker Service is Running ###
    ##########################################
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        ISACT=$( (sudo -u $sudo_user_name systemctl is-active docker ) 2>&1 )
        if [[ "$ISACT" != "active" ]]; then
            isNotice "Checking Docker service status. Waiting if not found."
            while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
                sudo -u $sudo_user_name systemctl start docker | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1
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
                ISACT=`sudo -u $sudo_user_name systemctl is-active docker`
                let X=X+1
                echo "$X"
            done
        fi
    fi
}

installDockerRootless()
{
	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
		if sudo grep -q "ROOTLESS" $sysctl; then
			isSuccessful "Docker Rootless appears to be installed."
        else
            echo ""
            echo "##########################################"
            echo "###      Install Docker Rootless       ###"
            echo "##########################################"
            echo ""

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Installing System Requirements."
            echo ""

            local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
            local docker_install_bashrc="/home/$CFG_DOCKER_INSTALL_USER/.bashrc"

            local result=$(sudo apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common uidmap dbus-user-session fuse-overlayfs)
            checkSuccess "Installing necessary packages"

            local result=$(sudo systemctl disable --now docker.service docker.socket)
            checkSuccess "Disabling Docker service & Socket"

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Installing slirp4netns."
            echo ""

            # slirp4netns update and install
            if ! command -v slirp4netns &> /dev/null; then
                isNotice "slirp4netns is not installed. Installing..."
                local result=$(sudo apt-get install -y slirp4netns)
                checkSuccess "Installing slirp4netns"
            else
                isNotice "slirp4netns is already installed"
                installed_version=$(slirp4netns --version | awk '{print $2}')
                latest_version=$(curl -s https://api.github.com/repos/rootless-containers/slirp4netns/releases/latest | grep tag_name | cut -d '"' -f 4)
                if [[ "$installed_version" != "$latest_version" ]]; then
                    isNotice "slirp4netns version $installed_version is outdated."
                    isNotice "Installing version $latest_version..."
                    local result=$(sudo apt-get update)
                    checkSuccess "Updating apt packages"
                    local result=$(sudo apt-get install -y slirp4netns)
                    checkSuccess "Installing slirp4netns"
                else
                    isSuccessful "slirp4netns version $installed_version is up to date"
                fi
            fi

            if [[ $(lsb_release -rs) == "10" ]]; then
                ((menu_number++))
                echo ""
                echo "---- $menu_number. Updating the sysctl file for Updating Debian 10."
                echo ""
                if sudo grep -q "kernel.unprivileged_userns_clone=1" $sysctl; then
                    isNotice "kernel.unprivileged_userns_clone=1 already exists in $sysctl"
                else
                    local result=$(echo "kernel.unprivileged_userns_clone=1" | sudo tee -a $sysctl > /dev/null)
                    checkSuccess "Adding kernel.unprivileged_userns_clone=1 to $sysctl..."
                    local result=$(sudo -u $sudo_user_name sysctl --system)
                    checkSuccess "Running sudo -u $sudo_user_name sysctl --system..."
                fi
            fi

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Update the .bashrc file."
            echo ""

            if ! grep -qF "# DOCKER ROOTLESS CONFIG FROM .sh SCRIPT" "$docker_install_bashrc"; then
                local result=$(echo '# DOCKER ROOTLESS CONFIG FROM .sh SCRIPT' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding rootless header to .bashrc"
 
                local result=$(echo 'export XDG_RUNTIME_DIR=/run/user/${UID}' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export path to .bashrc"

                local result=$(echo 'export PATH=/usr/bin:$PATH' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export path to .bashrc"

                local result=$(echo 'export DOCKER_HOST=unix:///run/user/${UID}/docker.sock' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export DOCKER_HOST path to .bashrc"

                local result=$(echo 'export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID}/bus"' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export DBUS_SESSION_BUS_ADDRESS path to .bashrc"

                isSuccessful "Added $CFG_DOCKER_INSTALL_USER to bashrc file"
            fi

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Setting up Rootless Docker."
            echo ""

            local result=$(sudo loginctl enable-linger $CFG_DOCKER_INSTALL_USER)
            checkSuccess "Adding automatic start (linger)"

            # Rootless Install
rootless_install=$(cat <<EOF
    curl -fsSL https://get.docker.com/rootless | sh && \
    systemctl --user start docker && \
    systemctl --user enable docker && \
    exit
EOF
)
            local result=$(runCommandForDockerInstallUser "$rootless_install")
            checkSuccess "Setting up Rootless for $CFG_DOCKER_INSTALL_USER"

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Setting up additional Sliprp4netns changes."
            echo ""

            # Sliprp4netns Install
            systemd_user_dir="/home/$CFG_DOCKER_INSTALL_USER/.config/systemd/user"
            local result=$(runCommandForDockerInstallUser "mkdir -p $systemd_user_dir")
            checkSuccess "Create the systemd user directory if it doesn't exist"

            local result=$(runCommandForDockerInstallUser "mkdir -p $systemd_user_dir/docker.service.d")
            checkSuccess "Create the docker.service.d directory if it doesn't exist"

            override_conf_file="$systemd_user_dir/docker.service.d/override.conf"
            local result=$(sudo touch $override_conf_file)
            checkSuccess "Create the override.conf in docker.service.d"	
			
sudo bash -c "cat <<EOL > '$override_conf_file'
[Service]
Environment='DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns'
Environment='DOCKERD_ROOTLESS_ROOTLESSKIT_MTU=$CFG_NETWORK_MTU'
EOL"

            local result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER $override_conf_file)
            checkSuccess "Updating ownership for override.conf"

            local result=$(runCommandForDockerInstallUser "systemctl --user daemon-reload")
            checkSuccess "Reload the systemd user manager configuration"

			isNotice "Restarting docker service...this may take a moment..."
            local result=$(runCommandForDockerInstallUser "systemctl --user restart docker")
            checkSuccess "Setting up slirp4netns for Rootless Docker"

            local result=$(sudo cp $sysctl $sysctl.bak)
            checkSuccess "Backing up sysctl file"

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Setting up sysctl file to work with LetsEncrypt."
            echo ""

            # Update sysctl file
            if ! grep -qF "# DOCKER ROOTLESS CONFIG TO MAKE IT WORK WITH SSL LETSENCRYPT" "$sysctl"; then

                local result=$(echo '# DOCKER ROOTLESS CONFIG TO MAKE IT WORK WITH SSL LETSENCRYPT' | sudo tee -a "$sysctl" > /dev/null)
                checkSuccess "Adding rootless header to sysctl"

                local result=$(echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee -a "$sysctl" > /dev/null)
                checkSuccess "Adding ip_unprivileged_port_start to sysctl"

                local result=$(echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a "$sysctl" > /dev/null)
                checkSuccess "Adding unprivileged_userns_clone to sysctl"

                isSuccessful "Updated the sysctl with Docker Rootless configuration"
            fi

            local result=$(sudo sysctl --system)
            checkSuccess "Applying changes to sysctl"

            menu_number=0
        fi
    fi
}