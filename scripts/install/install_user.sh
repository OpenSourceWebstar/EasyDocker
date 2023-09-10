#!/bin/bash

installDockerManagerUser()
{
    if [[ "$CFG_REQUIREMENT_MANAGER" == "true" ]]; then
        if [[ "$OS" == [123] ]]; then
            if ! userExists "$CFG_DOCKER_MANAGER_USER"; then
                echo ""
                echo "############################################"
                echo "######   Installing $CFG_DOCKER_MANAGER_USER"
                echo "############################################"
                echo ""

                isNotice "User '$CFG_DOCKER_MANAGER_USER' does not exist, starting creation..."

                # Create the User Account
                result=$(sudo -u $easydockeruser useradd -m -s /bin/false "$CFG_DOCKER_MANAGER_USER")
                checkSuccess "Adding user via useradd command"
                
                result=$(echo "$CFG_DOCKER_MANAGER_USER:$CFG_DOCKER_MANAGER_PASS" | sudo -u $easydockeruser chpasswd)
                checkSuccess "Setting up login password"

                result=$(sudo -u $easydockeruser -u "$CFG_DOCKER_MANAGER_USER" mkdir -p /home/$CFG_DOCKER_MANAGER_USER/.ssh/)
                checkSuccess "Creating /home/$CFG_DOCKER_MANAGER_USER/.ssh folder"

                result=$(sudo -u $easydockeruser -u "$CFG_DOCKER_MANAGER_USER" ssh-keygen -t ed25519 -b 4096 -f "/home/$CFG_DOCKER_MANAGER_USER/.ssh/ssh_key_${CFG_INSTALL_NAME}_${CFG_DOCKER_MANAGER_USER}" -N "passphrase")
                checkSuccess "Setting up SSH-Keygen in /home/$CFG_DOCKER_MANAGER_USER/.ssh"

                # SSH configuration directory
                config_file="/home/$CFG_DOCKER_MANAGER_USER/.ssh/config"

                # Check if the config file already exists
                if [ -f "$config_file" ]; then
                    isNotice "The config file already exists. Updating the existing file..."
                else
                    result=$(createTouch "$config_file")
                    checkSuccess "Creating config file"
                    result=$(sudo chmod 600 "$config_file")
                    checkSuccess "Changing permissions to config file"
                fi

                # Add the ServerAliveInterval option to the config file
                if grep -q "ServerAliveInterval" "$config_file"; then
                    isNotice "ServerAliveInterval is already configured in the config file."
                else
                    result=$(echo -e "Host *\n  ServerAliveInterval 60" | sudo tee -a "$config_file" >/dev/null)
                    checkSuccess "Adding ServerAliveInterval to the config file."
                fi

                result=$(source ~/.bashrc)
                checkSuccess "Reloading .bashrc"


result=$(sudo -u $easydockeruser bash -c "cat >> /etc/ssh/sshd_config <<EOL

### EasyDocker Manager User Start
Match User $CFG_DOCKER_MANAGER_USER
    ChrootDirectory /home/$CFG_DOCKER_MANAGER_USER/
    ForceCommand internal-sftp -d /home/$CFG_DOCKER_MANAGER_USER/
    X11Forwarding no
    AllowTcpForwarding no
    PubkeyAuthentication yes
    PasswordAuthentication no
### EasyDocker Manager User End
EOL")

                checkSuccess "Updating SSH Server Configuration for the Manager User."

                # Reload SSH Service
                result=$(sudo -u $easydockeruser service ssh reload)
                checkSuccess "Reloading SSH Service"

                isSuccessful "User '$CFG_DOCKER_MANAGER_USER' with restricted SFTP access to '/home/$CFG_DOCKER_MANAGER_USER' has been set up."
            fi
        fi
    fi
}

uninstallDockerManagerUser()
{
    echo ""
    echo "############################################"
    echo "######     Removing $CFG_DOCKER_MANAGER_USER"
    echo "############################################"
    echo ""
	if [[ "$toolsremovedockermanageruser" == [yY] ]]; then
        if [[ "$OS" == [123] ]]; then
            # Remove the User Account and capture the exit status and output
            result=$(sudo -u $easydockeruser userdel -r "$CFG_DOCKER_MANAGER_USER" 2>&1)
            checkSuccess "Removing the '$CFG_DOCKER_MANAGER_USER' user"

            # Remove the Docker Manager User specific block from /etc/ssh/sshd_config
            result=$(sudo sed -i '/### EasyDocker Manager User Start/,/### EasyDocker Manager User End/d' /etc/ssh/sshd_config)
            checkSuccess "Removing the Docker Manager User from /etc/ssh/sshd_config."

            # Restart SSH Service
            result=$(sudo -u $easydockeruser service ssh restart)
            checkSuccess "Restarting SSH Service"
        fi
    fi
}