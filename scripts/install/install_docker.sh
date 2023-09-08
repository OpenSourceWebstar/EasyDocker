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
            #result=$(sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose)
            #checkSuccess "Download the official Docker Compose script"

            #result=$(sudo chmod +x /usr/local/bin/docker-compose)
            #checkSuccess "Make the script executable"

            #result=$(sapt install docker.io docker-compose -y)
            #checkSuccess "Make the script executable"

            result=$(sudo apt-get update)
            checkSuccess "Updating apt packages"

            result=$(sudo apt-get upgrade -y)
            checkSuccess "Upgrading packages"

            result=$(sudo apt-get install -y docker.io docker-compose)
            checkSuccess "Installing Docker and Docker Compose"

            result=$(sudo apt-get --purge autoremove -y)
            checkSuccess "Removing unused packages"

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
        result=$(sudo useradd -s /bin/bash -d "/home/$CFG_DOCKER_INSTALL_USER" -m -G sudo "$CFG_DOCKER_INSTALL_USER")
        checkSuccess "Creating $CFG_DOCKER_INSTALL_USER User."
        result=$(echo "$CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_PASS" | sudo chpasswd)
        checkSuccess "Setting password for $CFG_DOCKER_INSTALL_USER User."

        # Check if PermitRootLogin is set to "yes" before disabling it
        if grep -q 'PermitRootLogin yes' "$sshd_config"; then
            while true; do
                read -p "Do you want to disable login for the root user? (y/n): " rootdisableconfirm
                case "$rootdisableconfirm" in
                    [Yy]*)
                        result=$(sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' "$sshd_config")
                        checkSuccess "Disabling Root Login"
                        break
                        ;;
                    [Nn]*)
                        echo "No changes were made to PermitRootLogin."
                        break
                        ;;
                    *)
                        echo "Please enter 'y' or 'n'."
                        ;;
                esac
            done
        else
            echo "PermitRootLogin is already set to 'no' or not found in $sshd_config"
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
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
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
    fi
}

installDockerRootless()
{
	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
		if grep -q "ROOTLESS" $sysctl; then
			isNotice "Docker Rootless appears to be installed."
        else
            local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
            local docker_install_bashrc="/home/$CFG_DOCKER_INSTALL_USER/.bashrc"

            result=$(sudo apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common dbus-user-session fuse-overlayfs)
            checkSuccess "Installing necessary packages"

            # Debian
	        if [[ $OS == "1" ]]; then
                result=$(curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg)
                checkSuccess "Adding Docker's GPG key"

                result=$(echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null)
                checkSuccess "Adding Docker repository"

                result=$(sudo apt-get update)
                checkSuccess "Updating apt packages"

                result=$(sudo apt-get install -y docker-ce uidmap)
                checkSuccess "Installing Docker and uidmap"
            fi

            result=$(sudo systemctl disable --now docker.service docker.socket)
            checkSuccess "Disabling Docker service & Socket"

            # slirp4netns update and install
            if ! command -v slirp4netns &> /dev/null; then
                isNotice "slirp4netns is not installed. Installing..."
                result=$(sudo apt-get install -y slirp4netns)
                checkSuccess "Installing slirp4netns"
            else
                isNotice "slirp4netns is already installed"
                installed_version=$(slirp4netns --version | awk '{print $2}')
                latest_version=$(curl -s https://api.github.com/repos/rootless-containers/slirp4netns/releases/latest | grep tag_name | cut -d '"' -f 4)
                if [[ "$installed_version" != "$latest_version" ]]; then
                    isNotice "slirp4netns version $installed_version is outdated."
                    isNotice "Installing version $latest_version..."
                    result=$(sudo apt-get update)
                    checkSuccess "Updating apt packages"
                    result=$(sudo apt-get install -y slirp4netns)
                    checkSuccess "Installing slirp4netns"
                else
                    isSuccess "slirp4netns version $installed_version is up to date"
                fi
            fi

            # Updating Debian 10
            if [[ $(lsb_release -rs) == "10" ]]; then
                if grep -q "kernel.unprivileged_userns_clone=1" $sysctl; then
                    isNotice "kernel.unprivileged_userns_clone=1 already exists in $sysctl"
                else
                    result=$(echo "kernel.unprivileged_userns_clone=1" | sudo tee -a $sysctl > /dev/null)
                    checkSuccess "Adding kernel.unprivileged_userns_clone=1 to $sysctl..."
                    result=$(sudo sysctl --system)
                    checkSuccess "Running sudo sysctl --system..."
                fi
            fi
               
            # Update .bashrc file
            if ! grep -qF "# DOCKER ROOTLESS CONFIG FROM .sh SCRIPT" "$docker_install_bashrc"; then
                result=$(echo '# DOCKER ROOTLESS CONFIG FROM .sh SCRIPT' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding rootless header to .bashrc"

                result=$(echo 'export XDG_RUNTIME_DIR=/home/'$CFG_DOCKER_INSTALL_USER'/.docker/run' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export path to .bashrc"

                result=$(echo 'export PATH=/home/'$CFG_DOCKER_INSTALL_USER'/bin:$PATH' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export path to .bashrc"

                result=$(echo 'export DOCKER_HOST=unix:///home/'$CFG_DOCKER_INSTALL_USER'/.docker/run/docker.sock' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export DOCKER_HOST path to .bashrc"

                result=$(echo 'export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/'$docker_install_user_id'/bus"' | sudo tee -a "$docker_install_bashrc" > /dev/null)
                checkSuccess "Adding export DBUS_SESSION_BUS_ADDRESS path to .bashrc"

                isSuccessful "Added $CFG_DOCKER_INSTALL_USER to bashrc file"
            fi

            isNotice "Please enter the password for the $CFG_DOCKER_INSTALL_USER user"

result=$(ssh -o StrictHostKeyChecking=no $CFG_DOCKER_INSTALL_USER@localhost 'bash -s' << EOF
    dockerd-rootless-setuptool.sh install && \
    systemctl --user start docker && \
    systemctl --user enable docker && \
    exit
EOF
)
checkSuccess "Setting up Rootless for $CFG_DOCKER_INSTALL_USER"
            result=$(sudo loginctl enable-linger $CFG_DOCKER_INSTALL_USER)
            checkSuccess "Adding automatic start (linger)"

            result=$(sudo cp $sysctl $sysctl.bak)
            checkSuccess "Backing up sysctl file"

            # Update sysctl file
            if ! grep -qF "# DOCKER ROOTLESS CONFIG TO MAKE IT WORK WITH SSL LETSENCRYPT" "$sysctl"; then

                result=$(echo '# DOCKER ROOTLESS CONFIG TO MAKE IT WORK WITH SSL LETSENCRYPT' | sudo tee -a "$sysctl" > /dev/null)
                checkSuccess "Adding rootless header to sysctl"

                result=$(echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee -a "$sysctl" > /dev/null)
                checkSuccess "Adding ip_unprivileged_port_start to sysctl"

                result=$(echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a "$sysctl" > /dev/null)
                checkSuccess "Adding unprivileged_userns_clone to sysctl"

                isSuccess "Updated the sysctl with Docker Rootless configuration"
            fi

            result=$(sudo sysctl --system)
            checkSuccess "Applying changes to sysctl"

            #result=$(sudo reboot)
            #checkSuccess "Restarting server... please run 'easydocker' again after the server is back online"
        fi
    fi
}