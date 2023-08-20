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
                result=$(sudo useradd -m -s /bin/false "$CFG_DOCKER_MANAGER_USER")
                checkSuccess "Adding user via useradd command"
                
                result=$(echo "$CFG_DOCKER_MANAGER_USER:$CFG_DOCKER_MANAGER_PASS" | sudo chpasswd)
                checkSuccess "Setting up login password"

                # File & Folder Permissions
                # Setting up chown as root for chroot users
                result=$(sudo chown -R root:root $base_dir)
                checkSuccess "Chown $base_dir folder to root for chroot access"

                result=$(sudo chmod -R 755 $base_dir)
                checkSuccess "Set appropriate permissions for $base_dir SSH folder"

                result=$(mkdir -p $ssh_dir$CFG_DOCKER_MANAGER_USER)
                checkSuccess "Creating folder for $CFG_DOCKER_MANAGER_USER to use"

                result=$(sudo chown -R $CFG_DOCKER_MANAGER_USER:$CFG_DOCKER_MANAGER_USER $ssh_dir$CFG_DOCKER_MANAGER_USER)
                checkSuccess "Chown generated $CFG_DOCKER_MANAGER_USER SSH folder"

                result=$(sudo chmod -R 755 $ssh_dir$CFG_DOCKER_MANAGER_USER)
                checkSuccess "Set appropriate permissions for $CFG_DOCKER_MANAGER_USER SSH folder"

                result=$(sudo setfacl -Rm u:"$CFG_DOCKER_MANAGER_USER":r-x "$base_dir")
                checkSuccess "Grant read-only access for downloading files"

                result=$(sudo setfacl -Rm u:"$CFG_DOCKER_MANAGER_USER":rwX "$base_dir")
                checkSuccess "Grant read-write access for uploading new files but not deleting"

                result=$(sudo find "$base_dir" -type f -exec setfacl -m u:"$CFG_DOCKER_MANAGER_USER":-w {} +)
                checkSuccess "Prevent the user from deleting existing files"

                result=$(sudo -u "$CFG_DOCKER_MANAGER_USER" mkdir -p /home/$CFG_DOCKER_MANAGER_USER/.ssh/)
                checkSuccess "Creating /home/ .ssh folder for $CFG_DOCKER_MANAGER_USER to use"

                result=$(sudo -u "$CFG_DOCKER_MANAGER_USER" mkdir -p $ssh_dir$CFG_DOCKER_MANAGER_USER)
                checkSuccess "Creating $CFG_DOCKER_MANAGER_USER SSH Folder for $CFG_DOCKER_MANAGER_USER to use"             

                result=$(sudo -u "$CFG_DOCKER_MANAGER_USER" ssh-keygen -t ed25519 -b 4096 -f "/home/$CFG_DOCKER_MANAGER_USER/.ssh/ssh_key_${CFG_INSTALL_NAME}_${CFG_DOCKER_MANAGER_USER}" -N "passphrase")
                checkSuccess "Setting up SSH-Keygen in $ssh_dir$CFG_DOCKER_MANAGER_USER"

                result=$(sudo mv "/home/$CFG_DOCKER_MANAGER_USER/.ssh/ssh_key_${CFG_INSTALL_NAME}_${CFG_DOCKER_MANAGER_USER}.pub" "$ssh_dir$CFG_DOCKER_MANAGER_USER/ssh_key_${CFG_INSTALL_NAME}_${CFG_DOCKER_MANAGER_USER}.pub")
                checkSuccess "Moving the Public SSH Key to $ssh_dir$CFG_DOCKER_MANAGER_USER"

                # SSH configuration directory
                config_file="$ssh_dir$CFG_DOCKER_MANAGER_USER/config"

                # Check if the config file already exists
                if [ -f "$config_file" ]; then
                    isNotice "The config file already exists. Updating the existing file..."
                else
                    result=$(touch "$config_file")
                    checkSuccess "Creating config file"
                    result=$(chmod 600 "$config_file")
                    checkSuccess "Changing permissions to config file"
                fi

                # Add the ServerAliveInterval option to the config file
                if grep -q "ServerAliveInterval" "$config_file"; then
                    isNotice "ServerAliveInterval is already configured in the config file."
                else
                    result=$(echo -e "Host *\n  ServerAliveInterval 60" >> "$config_file")
                    checkSuccess "Adding ServerAliveInterval to the config file."
                fi

                result=$(source ~/.bashrc)
                checkSuccess "Reloading .bashrc"


result=$(sudo bash -c "cat >> /etc/ssh/sshd_config <<EOL

AuthorizedKeysFile /docker/ssh/%u/authorized_keys
### EasyDocker Manager User Start
Match User $CFG_DOCKER_MANAGER_USER
    ChrootDirectory $base_dir
    ForceCommand internal-sftp /ssh/$CFG_DOCKER_MANAGER_USER/
    X11Forwarding no
    AllowTcpForwarding no
    PubkeyAuthentication yes
    PasswordAuthentication yes
### EasyDocker Manager User End
EOL")

                checkSuccess "Updating SSH Server Configuration for the Manager User."
                
                # Fix Perms
                result=$(sudo chmod -R 755 $base_dir)
                checkSuccess "Adjusting permissions for all files in $base_dir"
                result=$(sudo chmod 700 $ssh_dir)
                checkSuccess "Adjusting permissions for $base_dir"
                result=$(sudo chmod 700 $ssh_dir$CFG_DOCKER_MANAGER_USER/)
                updateSSHPermissions;

                # Reload SSH Service
                result=$(sudo service ssh reload)
                checkSuccess "Reloading SSH Service"

                isSuccessful "User '$CFG_DOCKER_MANAGER_USER' with restricted SFTP access to '$base_dir' has been set up."
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
            result=$(sudo rm -rf $ssh_dir$CFG_DOCKER_MANAGER_USER)
            checkSuccess "Removing $CFG_DOCKER_MANAGER_USER SSH key folder"

            # Remove all ACL entries from files
            result=$(sudo find "$base_dir" -type f -exec setfacl -b {} +)
            checkSuccess "Removed all ACL entries from files."

            # Remove read-only access and read-write access without delete permission
            result=$(sudo setfacl -Rx u:"$CFG_DOCKER_MANAGER_USER" "$base_dir")
            checkSuccess "Removed read-only access and read-write access without delete permission."

            # Remove the User Account and capture the exit status and output
            result=$(sudo userdel -r "$CFG_DOCKER_MANAGER_USER" 2>&1)
            checkSuccess "Removing the '$CFG_DOCKER_MANAGER_USER' user"

            # Remove the Docker Manager User specific block from /etc/ssh/sshd_config
            result=$(sudo sed -i '/### EasyDocker Manager User Start/,/### EasyDocker Manager User End/d' /etc/ssh/sshd_config)
            checkSuccess "Removing the Docker Manager User from /etc/ssh/sshd_config."

            # Restart SSH Service
            result=$(sudo service ssh restart)
            checkSuccess "Restarting SSH Service"
        fi
    fi
}