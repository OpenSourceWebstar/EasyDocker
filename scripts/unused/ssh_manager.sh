#!/bin/bash

# Used for Sending SSH keys to remote hosts
installSSHRemoteList()
{
    if [[ "$CFG_REQUIREMENT_SSHREMOTE" == "true" ]]; then
        if [[ "$setupSSHRemoteKeys" == true ]]; then
            local app_name="$1"
            echo ""
            echo "############################################"
            echo "######       Remote SSH Install       ######"
            echo "############################################"
            echo ""

            # Check if sqlite3 is available
            if ! command -v sqlite3 &> /dev/null; then
                isNotice "sqlite3 command not found. Make sure it's installed."
                return 1
            fi

            # Check if database file is available
            if [ ! -f "$docker_dir/$db_file" ] ; then
                isNotice "Database file not found. Make sure it's installed."
                return 1
            fi

            ssh_hosts_line=$(grep '^CFG_IPS_SSH_SETUP=' $configs_dir$config_file_general)
            if [ -z "$ssh_hosts_line" ]; then
                echo "No hosts found in the config file or the file is empty."
                echo ""
            else
                ssh_hosts=${ssh_hosts_line#*=}
                IFS=',' read -ra ip_addresses <<< "$ssh_hosts"

                for ip in "${ip_addresses[@]}"; do
                    results=$(sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM ssh WHERE ip = '$ip';")
                    if [ "$results" -eq 0 ]; then
                        isNotice "Copying SSH public key to $ip..."
                        installSSHKeyToHost "$ip"
                        databaseSSHInsert $ip;
                    else
                        if [[ "$toolinstallremotesshlist" == [yY] ]]; then
                            while true; do
                                isNotice "Make sure you have the host setup and ready with the EasyDocker preinstallation before doing this!"
                                isQuestion "Is $ip prepared with the EasyDocker pre-installation? (y/n): "
                                read -rp "" ishostsetupprompt
                                if [[ -n "$ishostsetupprompt" ]]; then
                                    break
                                fi
                                isNotice "Please provide a valid input."
                            done
                            if [[ "$ishostsetupprompt" == [yY] ]]; then
                                while true; do
                                    isQuestion "Record found for $ip. Do you want to reinstall? (y/n): "
                                    read -rp "" toolreinstallremotessh
                                    if [[ -n "$toolreinstallremotessh" ]]; then
                                        break
                                    fi
                                    isNotice "Please provide a valid input."
                                done
                                if [[ "$toolreinstallremotessh" == [yY] ]]; then
                                    ## Start copy
                                    isNotice "Copying SSH public key to $ip..."
                                    installSSHKeyToHost "$ip"
                                    databaseSSHInsert $ip;
                                fi
                            else
                                isError "Please setup your host $ip with the EasyDocker pre-installation"
                            fi
                        else
                        isNotice "All SSH Keys are already setup."
                        isNotice "'Install Remote SSH Keys' option in the tools list if you want to reinstall any keys."
                        fi
                    fi
                done
                # Random note - Not sure how secure having all passwords saved for SSH, so not adding
            fi
        fi
    fi
}

installSSHKeyToHost() 
{
    local host=$1
    local ssh_key_file="$ssh_dir$CFG_DOCKER_MANAGER_USER/ssh_key_${CFG_INSTALL_NAME}_${CFG_DOCKER_MANAGER_USER}.pub"

    # Check if the specified SSH key file exists
    if [ ! -f "$ssh_key_file" ]; then
        isError "The SSH key file '$ssh_key_file' does not exist."
        return 1
    fi

# Copy the SSH public key to the remote directory using sftp
local result=$(sftp -oBatchMode=no -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null "$CFG_DOCKER_MANAGER_USER@$host" <<EOF
cd "ssh/$CFG_DOCKER_MANAGER_USER"
put "$ssh_key_file"
EOF
)
    checkSuccess "Transfering the SSH key to $host."
    isNotice "It will take time for the new SSH Key to be installed into the authorized_keys."
    isNotice "This depends entirely on the setup of EasyDocker on the host, but usually is 5 minutes"
}


# Function to update the authorized_keys file and the database
updateAuthorizedKeysAndDatabase()
{
    if [[ "$CFG_REQUIREMENT_SSHREMOTE" == "true" ]]; then
        local ssh_directory="$ssh_dir$CFG_DOCKER_MANAGER_USER"  # Define ssh_directory here

        # Create an array to keep track of processed keys
        local processed_keys=()

        # Loop through the key files in the directory
        for key_file in "$ssh_directory"/*.pub; do
            if [ -f "$key_file" ]; then
                # Get the filename without the path
                key_filename=$(basename "$key_file")

                # Check if the key has already been processed
                if printf '%s\n' "${processed_keys[@]}" | grep -q -F "$key_filename"; then
                    continue  # Skip processing this key as it has already been processed
                fi

                #echo "DEBUG: Adding key from file: $key_file"
                #echo "DEBUG: Key filename: $key_filename"

                # Add the key to authorized_keys and the database
                addSSHKeyToAuthorizedKeysAndDatabase "$key_file" "$ssh_directory"

                # Add the key filename to the processed_keys array
                processed_keys+=("$key_filename")
            fi
        done

        # Check for keys in the database that are no longer present in the directory
        # and remove them from the database and authorized_keys file
        while IFS= read -r db_key_filename; do
            if ! ls "$ssh_directory"/*.pub | grep -q -F "$db_key_filename"; then
                # Remove the key from the database and authorized_keys file
                removeSSHKeyFromAuthorizedKeysAndDatabase "$db_key_filename" "$ssh_directory"
            fi
        done < <(sqlite3 "$docker_dir/$db_file" "SELECT name FROM ssh_keys;")
    fi
}

# Function to scan the folder for missing .pub keys and process them
databaseSSHScanForKeys() 
{
    echo ""
    echo "############################################"
    echo "######          SSH Key Scan          ######"
    echo "############################################"
    echo ""

    local ssh_directory="$ssh_dir$CFG_DOCKER_MANAGER_USER"

    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if database file is available
    if [ ! -f "$docker_dir/$db_file" ] ; then
        isNotice "Database file not found. Make sure it's installed."
        return 1
    fi

    # Remove old keys from the authorized_keys file and the database
    updateAuthorizedKeysAndDatabase "$ssh_directory"

    updateSSHPermissions

    # Reloading SSH Service
    local result=$(sudo service ssh reload)
    checkSuccess "Reloading the SSH Service"

    isSuccessful "SSH Key Scan completed successfully."
}

# Function to add an SSH public key from a file to the authorized_keys file and the database
addSSHKeyToAuthorizedKeysAndDatabase() 
{
    local key_file="$1"
    local ssh_directory="$2"
    local auth_key_file="$ssh_directory/authorized_keys"  # Define auth_key_file here

    # Get the filename without the path
    local key_filename=$(basename "$key_file")

    #echo "DEBUG: Adding SSH public key from $key_filename to authorized_keys file."

    # Check if the specified SSH public key file exists
    if [ -f "$key_file" ]; then
        # Ensure the authorized_keys file is empty or create it if it doesn't exist
        if [ ! -f "$auth_key_file" ]; then
            createTouch "$auth_key_file" $docker_install_user
        fi

        # Check if the key already exists in the file
        local ssh_public_key=$(cat "$key_file")
        local key_file_name=$(basename "$key_file")
        local auth_key_file_name=$(basename "$auth_key_file")

        if ! grep -Fxq "$ssh_public_key" "$auth_key_file"; then
            #echo "DEBUG: Adding key from file: $key_file"
            #echo "DEBUG: Key filename: $key_filename"

            # Add the key to the authorized_keys file
            echo "$ssh_public_key" >> "$auth_key_file"
            checkSuccess "SSH public key from $key_filename added to $auth_key_file_name."
        #else
            #echo "NOTICE: SSH Key already exists in the authorized_keys file. Skipping..."
        fi

        # Hash the public key content
        local ssh_public_key_hash=$(echo "$ssh_public_key" | sha256sum | cut -d' ' -f1)

        # Check if the key already exists in the database
        local key_in_db=$(sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM ssh_keys WHERE name = '$key_filename';")

        if [ "$key_in_db" -eq 0 ]; then
            # Key doesn't exist in the database, insert it
            local result=$(sqlite3 "$docker_dir/$db_file" "INSERT INTO ssh_keys (name, hash, date, time) VALUES ('$key_filename', '$ssh_public_key_hash', '$current_date', '$current_time');")
            checkSuccess "SSH public key from $key_filename added to the database."
        else
            # Key exists in the database, check if its content has changed
            local db_key_hash=$(sqlite3 "$docker_dir/$db_file" "SELECT hash FROM ssh_keys WHERE name = '$key_filename';")
            if [ "$db_key_hash" != "$ssh_public_key_hash" ]; then
                # Key content has changed, update the record
                local result=$(sqlite3 "$docker_dir/$db_file" "UPDATE ssh_keys SET hash = '$ssh_public_key_hash', date = '$current_date', time = '$current_time' WHERE name = '$key_filename';")
                checkSuccess "SSH Key content from $key_filename updated in the database."
            #else
                #echo "NOTICE: SSH Key content from $key_filename already exists in the database. Skipping update..."
            fi
        fi
    else
        isError "SSH public key file not found: $key_filename"
    fi
}

# Function to remove an SSH public key from the authorized_keys file and the database
removeSSHKeyFromAuthorizedKeysAndDatabase() 
{
    if [[ "$CFG_REQUIREMENT_SSHREMOTE" == "true" ]]; then
        local key_filename="$1"
        local ssh_directory="$2"  # Define ssh_directory here
        local auth_key_file="$ssh_directory/authorized_keys"  # Define auth_key_file here

        # Remove the key from the authorized_keys file
        local result=$(sudo sed -i "/$key_filename/d" "$auth_key_file")
        checkSuccess "SSH public key '$key_filename' removed from authorized_keys file."

        # Remove the key from the database
        db_query="DELETE FROM ssh_keys WHERE name = '$key_filename';"
        local result=$(sqlite3 "$docker_dir/$db_file" "$db_query")
        checkSuccess "SSH public key '$key_filename' removed from the database."
    fi
}

updateSSHPermissions()
{
    local result=$(sudo chmod 700 $ssh_dir$CFG_DOCKER_MANAGER_USER/)
    #checkSuccess "Adjusting permissions for $ssh_dir$CFG_DOCKER_MANAGER_USER"

    # SSH configuration directory
    auth_key="$ssh_dir$CFG_DOCKER_MANAGER_USER/authorized_keys"
    # Check if the config file already exists
    if [ -f "$auth_key" ]; then
        local result=$(sudo chmod 600 $auth_key)
        #checkSuccess "Adjusting permissions for authorized_keys"
    fi

    local result=$(sudo chmod +rx $ssh_dir $ssh_dir$CFG_DOCKER_MANAGER_USER)
    #checkSuccess "Adding read and write permissions for ssh folders"
    local result=$(sudo chown -R $CFG_DOCKER_MANAGER_USER:$CFG_DOCKER_MANAGER_USER $ssh_dir$CFG_DOCKER_MANAGER_USER)
    #checkSuccess "Adding chown to dockermanager user for ssh folders"
    local result=$(sudo find $ssh_dir$CFG_DOCKER_MANAGER_USER -type f -name "*.pub" -exec sudo chmod 600 {} \;)
    #checkSuccess "Updating all permissions of keys to 600"
}
#!/bin/bash

installDockerManagerUser()
{
    if [[ "$CFG_REQUIREMENT_MANAGER" == "true" ]]; then
        if [[ "$OS" == [1234567] ]]; then
            if ! userExists "$CFG_DOCKER_MANAGER_USER"; then
                echo ""
                echo "############################################"
                echo "######   Installing $CFG_DOCKER_MANAGER_USER"
                echo "############################################"
                echo ""

                isNotice "User '$CFG_DOCKER_MANAGER_USER' does not exist, starting creation..."

                # Create the User Account
                local result=$(sudo useradd -m -s /bin/false "$CFG_DOCKER_MANAGER_USER")
                checkSuccess "Adding user via useradd command"
                
                local result=$(echo "$CFG_DOCKER_MANAGER_USER:$CFG_DOCKER_MANAGER_PASS" | sudo chpasswd)
                checkSuccess "Setting up login password"

                local result=$(sudo -u "$CFG_DOCKER_MANAGER_USER" mkdir -p /home/$CFG_DOCKER_MANAGER_USER/.ssh/)
                checkSuccess "Creating /home/$CFG_DOCKER_MANAGER_USER/.ssh folder"

                local result=$(sudo -u "$CFG_DOCKER_MANAGER_USER" ssh-keygen -t ed25519 -b 4096 -f "/home/$CFG_DOCKER_MANAGER_USER/.ssh/ssh_key_${CFG_INSTALL_NAME}_${CFG_DOCKER_MANAGER_USER}" -N "passphrase")
                checkSuccess "Setting up SSH-Keygen in /home/$CFG_DOCKER_MANAGER_USER/.ssh"

                # SSH configuration directory
                config_file="/home/$CFG_DOCKER_MANAGER_USER/.ssh/config"

                # Check if the config file already exists
                if [ -f "$config_file" ]; then
                    isNotice "The config file already exists. Updating the existing file..."
                else
                    local result=$(createTouch "$config_file" $docker_install_user)
                    checkSuccess "Creating config file"
                    local result=$(sudo chmod 600 "$config_file")
                    checkSuccess "Changing permissions to config file"
                fi

                # Add the ServerAliveInterval option to the config file
                if sudo grep -q "ServerAliveInterval" "$config_file"; then
                    isNotice "ServerAliveInterval is already configured in the config file."
                else
                    local result=$(echo -e "Host *\n  ServerAliveInterval 60" | sudo tee -a "$config_file" >/dev/null)
                    checkSuccess "Adding ServerAliveInterval to the config file."
                fi

                local result=$(source ~/.bashrc)
                checkSuccess "Reloading .bashrc"


local result=$(sudo bash -c "cat >> $sshd_config <<EOL

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
                local result=$(sudo service ssh reload)
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
        if [[ "$OS" == [1234567] ]]; then
            # Remove the User Account and capture the exit status and output
            local result=$(sudo userdel -r "$CFG_DOCKER_MANAGER_USER" 2>&1)
            checkSuccess "Removing the '$CFG_DOCKER_MANAGER_USER' user"

            # Remove the Docker Manager User specific block from $sshd_config
            local result=$(sudo sed -i '/### EasyDocker Manager User Start/,/### EasyDocker Manager User End/d' $sshd_config)
            checkSuccess "Removing the Docker Manager User from $sshd_config."

            # Restart SSH Service
            local result=$(sudo service ssh restart)
            checkSuccess "Restarting SSH Service"
        fi
    fi
}