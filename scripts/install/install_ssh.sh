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
                                read -r "" ishostsetupprompt
                                if [[ -n "$ishostsetupprompt" ]]; then
                                    break
                                fi
                                isNotice "Please provide a valid input."
                            done
                            if [[ "$ishostsetupprompt" == [yY] ]]; then
                                while true; do
                                    isQuestion "Record found for $ip. Do you want to reinstall? (y/n): "
                                    read -r "" toolreinstallremotessh
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


# Function to compute the SHA-256 hash of a string
computeSHA256Hash() 
{
    echo -n "$1" | sha256sum | cut -d " " -f 1
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
            createTouch "$auth_key_file" $CFG_DOCKER_INSTALL_USER
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

installSSHKeysForDownload()
{
    local flag="$1"
    if [[ "$SSHKEY_SETUP_NEEDED" == "true" ]]; then
        echo ""
        echo "############################################"
        echo "######        SSH Key Install         ######"
        echo "############################################"
        echo ""

        ssh_new_key="false"

        # Fix permissions for SSH Directory
        local result=$(sudo chmod 0775 "$ssh_dir" > /dev/null 2>&1)
        checkSuccess "Updating $ssh_dir with 0775 permissions."
        local result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$ssh_dir" > /dev/null 2>&1)
        checkSuccess "Updating $ssh_dir with $CFG_DOCKER_INSTALL_USER ownership."

        # Check if SSH Keys are enabled
        if [[ "$CFG_REQUIREMENT_SSHKEY_ROOT" == "true" ]]; then
            generateSSHSetupKeyPair "root" $flag
        fi
        if [[ "$CFG_REQUIREMENT_SSHKEY_ROOT" == "true" ]]; then
            generateSSHSetupKeyPair "$sudo_user_name" $flag
        fi
        if [[ "$CFG_REQUIREMENT_SSHKEY_ROOT" == "true" ]]; then
            generateSSHSetupKeyPair "$CFG_DOCKER_INSTALL_USER" $flag
        fi

        # Install if keys have been setup
        if [[ "$ssh_new_key" == "true" ]]; then
            installApp sshdownload;
        fi

        if [[ "$CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS" == "true" ]]; then
            disableSSHPasswords;
        fi
    fi
}

checkSSHSetupKeyPair() 
{
    local username="$1"

    local private_key_file="${CFG_INSTALL_NAME}_sshkey_$username"
    local private_key_path="${ssh_dir}private"
    local private_key_full="$private_key_path/$private_key_file"

    local public_key_file="$private_key_file.pub"
    local public_key_path="${ssh_dir}public"
    local public_key_full="$public_key_path/$public_key_file"

    # Check if both private and public key files exist
    if [ -f "$private_key_full" ] && [ -f "$public_key_full" ]; then
        return 0  # Key pair exists
    else
        return 1  # Key pair does not exist
    fi
}

generateSSHSetupKeyPair() 
{
    local username="$1"
    local flag="$2"

    local private_key_file="${CFG_INSTALL_NAME}_sshkey_$username"
    local private_key_path="${ssh_dir}private"
    local private_key_full="$private_key_path/$private_key_file"

    local public_key_file="$private_key_file.pub"
    local public_key_path="${ssh_dir}public"
    local public_key_full="$public_key_path/$public_key_file"

    local ssh_should_setup=false

    # Check if the directory exists; if not, create it
    if [ ! -d "$private_key_path" ]; then
        local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER $private_key_path)
        checkSuccess "Creating $(basename "$private_key_path") folder"
    fi
    if [ ! -d "$public_key_path" ]; then
        local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER $public_key_path)
        checkSuccess "Creating $(basename "$public_key_path") folder"
    fi

    regenerateSSHKey()
    {
        while true; do
            isQuestion "Do you want to generate new SSH Key(s) for the $username user? (y/n): "
            read -rp "" key_regenerate_accept
            case "$key_regenerate_accept" in
                [Yy]*)
                    generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" reinstall;
                    break
                    ;;
                [Nn]*)
                    # No action needed
                    break
                    ;;
                *)
                    echo "Please enter 'y' or 'n'."
                    ;;
            esac
        done
    }

    local username_caps=$(echo "$username" | tr '[:lower:]' '[:upper:]')
    local sshkey_requirement="CFG_REQUIREMENT_SSHKEY_${USERNAMEINCAPS}"
    local sshkey_requirement_data="${!sshkey_requirement}"

    # Check if the private and public keys exist
    if [ -f "$private_key_full" ] && [ -f "$public_key_full" ] && [[ "$flag" != "install" ]]; then
        local ssh_should_setup=true
        echo ""
        isNotice "SSH Key pair for $username already exists: $(basename "$private_key_full") / $(basename "$public_key_full")"
        echo ""
        if [[ "$sshkey_requirement_data" == "true" ]]; then
            generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" reinstall;
        else
            regenerateSSHKey;
        fi
    fi

    # If public key does not exist
    if [ ! -f "$public_key_full" ] && [[ "$ssh_should_setup" == "false" ]]; then
        local ssh_should_setup=true
        echo ""
        isNotice "SSH Private key for $username exists without a corresponding public key: $(basename "$private_key_full")"
        echo ""
        if [[ "$sshkey_requirement_data" == "true" ]]; then
            generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" reinstall;
        else
            regenerateSSHKey;
        fi
    fi

    if [ ! -f "$private_key_full" ] && [ -f "$public_key_full" ] && [[ "$ssh_should_setup" == "false" ]]; then
        generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" install;
    fi
}

generateSSHKeyPair()
{
    local username="$1"
    local private_key_path="$2"
    local private_key_full="$3"
    local public_key_full="$4"
    local flag="$5"
    echo ""
    echo ""
    echo "############################################"
    echo "######   SSH Key Generation for $username"
    echo "############################################"
    echo ""

    if [[ "$flag" == "reinstall" ]]; then
        if [ -f "$private_key_full" ]; then
            result=$(sudo rm $private_key_full)
            checkSuccess "Deleted old private SSH key $(basename "$private_key_full")"
        fi
        if [ -f "$public_key_full" ]; then
            result=$(sudo rm $public_key_full)
            checkSuccess "Deleted old public SSH key $(basename "$public_key_full")"
        fi
    fi

    if [[ "$username" == "root" ]]; then
        local ssh_passphrase=$CFG_SSHKEY_PASSPHRASE_ROOT
    elif [[ "$username" == "$sudo_user_name" ]]; then
        local ssh_passphrase=$CFG_SSHKEY_PASSPHRASE_ROOT
    elif [[ "$username" == "$CFG_DOCKER_INSTALL_USER" ]]; then
        local ssh_passphrase=$CFG_SSHKEY_PASSPHRASE_DOCKERINSTALL
    fi

    # Supply $CFG_DOCKER_INSTALL_USER password for sudo usage
    if [[ "$username" == "$CFG_DOCKER_INSTALL_USER" ]]; then
        result=$(echo -e "$CFG_DOCKER_INSTALL_PASS\n$ssh_passphrase\n$ssh_passphrase" | sudo -u $username ssh-keygen -t ed25519 -f "$ssh_dir/$(basename "$private_key_full")" -C "$CFG_EMAIL" -N "" && sudo -u $username cat "$ssh_dir/$(basename "$private_key_full").pub" | sudo -u $username tee -a "$ssh_dir/$(basename "$private_key_full")" > /dev/null)
        checkSuccess "New ED25519 key pair generated for $username"
    else
        result=$(echo -e "$ssh_passphrase\n$ssh_passphrase" | sudo -u $username sudo ssh-keygen -t ed25519 -f "$ssh_dir/$(basename "$private_key_full")" -C "$CFG_EMAIL" -N "" && sudo -u $username cat "$ssh_dir/$(basename "$private_key_full").pub" | sudo tee -a "$ssh_dir/$(basename "$private_key_full")" > /dev/null)
        checkSuccess "New ED25519 key pair generated for $username"
    fi

    if [ -f "$ssh_dir/$(basename $private_key_full)" ]; then
        updateFileOwnership $ssh_dir/$(basename $private_key_full) $CFG_DOCKER_INSTALL_USER $CFG_DOCKER_INSTALL_USER
        result=$(sudo mv "$ssh_dir/$(basename "$private_key_full")" "$private_key_full")
        checkSuccess "Private key moved to $private_key_full"
    fi

    if [ -f "$ssh_dir/$(basename $public_key_full)" ]; then
        updateFileOwnership $ssh_dir/$(basename $public_key_full) $CFG_DOCKER_INSTALL_USER $CFG_DOCKER_INSTALL_USER
        result=$(sudo mv "$ssh_dir/$(basename "$public_key_full")" "$public_key_full")
        checkSuccess "Public key moved to $public_key_full"
    fi

    result=$(createTouch "$ssh_dir/public/$(basename $private_key_full)" $CFG_DOCKER_INSTALL_USER)
    checkSuccess "Creating the passphrase txt to private folder."

    result=$(echo "$ssh_passphrase" | sudo tee -a "$ssh_dir/public/$(basename $private_key_full)" > /dev/null)
    checkSuccess "Adding the ssh_passphrase to the $(basename "$private_key_full").txt file."

    result=$(sudo chmod 644 $ssh_dir/private/$(basename $private_key_full))
    checkSuccess "Updating permissions for $(basename $private_key_full)"

    setupSSHAuthorizedKeys $username $public_key_full;

    updateSSHHTMLSSHKeyLinks;

    ssh_new_key=true
}

setupSSHAuthorizedKeys()
{
    local username="$1"
    local public_key_full="$2"

    if [[ "$username" == "root" ]]; then
        local ssh_path="/root/.ssh" 
    else
        local ssh_path="/home/$username/.ssh" 
    fi

    # Check if the directory exists; if not, create it
    if [ ! -d "$ssh_path" ]; then
        local result=$(mkdirFolders "loud" $username $ssh_path)
        checkSuccess "Creating $(basename "$private_key_path") folder"
        result=$(sudo chmod 700 $ssh_path)
        checkSuccess "Updating permissions for $ssh_path"
    else
        result=$(sudo chmod 700 $ssh_path)
        checkSuccess "Updating permissions for $ssh_path"
    fi

    if [ -f "${ssh_path}/authorized_keys" ]; then
        result=$(sudo rm ${ssh_path}/authorized_keys)
        checkSuccess "Deleted old authorized_keys file for user $username"
    fi

    result=$(sudo cp "$public_key_full" "${ssh_path}/authorized_keys")
    checkSuccess "Adding $(basename $public_key_full) to the Authorized_keys file for user $username"

    result=$(sudo chmod 600 ${ssh_path}/authorized_keys)
    checkSuccess "Updating permissions for ${username}'s authorized_keys file."

    updateFileOwnership "${ssh_path}/authorized_keys" $username $username

    result=$(sudo systemctl reload ssh)
    checkSuccess "Reloading SSH service"
}

disableSSHPasswords()
{
    echo ""
    isNotice "!!!!!!!!!!!!!!!! ***PROCEED WITH CAUTION*** !!!!!!!!!!!!!!!"
    echo ""
    isNotice "You are about to disable SSH Passwords Potentially blocking you out of your system!!!!"
    isNotice "Make sure you have downloaded and tested your SSH keys before disabling password login!!!"
    echo ""
    isNotice "The reason we disable ssh passwords is to improve security, allowing only SSH Key logins"
    isNotice "You will still be able to log in with SSH passwords via physical/console access, just not remotely!"
    echo ""
    # Define an array to store users without SSH keys
    users_without_keys=()

    # SSH Keys
    if [[ $CFG_REQUIREMENT_SSHKEY_ROOT == "true" ]]; then
        if checkSSHSetupKeyPair "root"; then
            isSuccessful "The SSH Key(s) for root appears to be set up."
        else
            isNotice "An SSH Key for root is not found, are you sure you want to disable SSH passwords?"
            users_without_keys+=("root")
        fi
    fi

    if [[ $CFG_REQUIREMENT_SSHKEY_EASYDOCKER == "true" ]]; then
        if checkSSHSetupKeyPair "$sudo_user_name"; then
            isSuccessful "The SSH Key(s) for $sudo_user_name appears to be set up."
        else
            isNotice "An SSH Key for $sudo_user_name is not found, are you sure you want to disable SSH passwords?"
            users_without_keys+=("$sudo_user_name")
        fi
    fi

    if [[ $CFG_REQUIREMENT_SSHKEY_DOCKERINSTALL == "true" ]]; then
        ### For SSH Key Setup
        if checkSSHSetupKeyPair "$CFG_DOCKER_INSTALL_USER"; then
            isSuccessful "The SSH Key(s) for $CFG_DOCKER_INSTALL_USER appears to be set up."
        else
            isNotice "An SSH Key for $CFG_DOCKER_INSTALL_USER is not found, are you sure you want to disable SSH passwords?"
            users_without_keys+=("$CFG_DOCKER_INSTALL_USER")
        fi
    fi

    # Display the list of users without SSH keys
    if [ ${#users_without_keys[@]} -gt 0 ]; then
        echo ""
        isNotice "SSH Key(s) were missing for the following users:"
        isNotice "Missing Users: ${users_without_keys[@]}"
        echo ""
        while true; do
            isQuestion "Do you want to install (i) the missing SSH keys or (c) continue or (x) to exit? (i/c/x): "
            read -rp "" disable_ssh_passwords
            case "$disable_ssh_passwords" in
                [iI]*)
                    installSSHKeysForDownload install;
                    break
                    ;;
                [cC]*)
                    disableSSHPasswordFunction;
                    break
                    ;;
                [xX]*)
                    break
                    ;;
                *)
                    echo "Please enter 'y' or 'n'."
                    ;;
            esac
        done
    else
        disableSSHPasswordFunction;
    fi
}

disableSSHPasswordFunction()
{
    if [[ $CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS == "true" ]]; then
        # Check if already disabled
        if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
            isSuccessful "Password Authentication is already disabled."
        else
            while true; do
                echo ""
                isQuestion "Do you want to disable SSH password logins? (y/n): "
                read -rp "" disable_ssh_passwords
                case "$disable_ssh_passwords" in
                    [Yy]*)
                        local backup_file="/etc/ssh/sshd_config_backup_$current_date-$current_time"
                        result=$(sudo cp /etc/ssh/sshd_config "$backup_file")
                        checkSuccess "Backup sshd_config file"

                        result=$(sudo sed -i '/^PasswordAuthentication/d' /etc/ssh/sshd_config)
                        checkSuccess "Removing existing PasswordAuthentication lines"

                        result=$(echo "PasswordAuthentication no" | sudo tee -a /etc/ssh/sshd_config)
                        checkSuccess "Add new PasswordAuthentication line at the end of sshd_config"

                        result=$(sudo systemctl restart sshd)
                        checkSuccess "Restart SSH service"
                        break
                        ;;
                    [Nn]*)
                        while true; do
                            isQuestion "Do you want to stop being asked to disable SSH Password logins? (y/n): "
                            read -r "" sshdisablepasswordask
                            if [[ "$sshdisablepasswordask" =~ ^[yYnN]$ ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input (y/n)."
                        done
                        if [[ "$sshdisablepasswordask" == [yY] ]]; then
                            local config_file="$configs_dir$config_file_requirements"
                            result=$(sudo sed -i 's/CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS=true/CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS=false/' $config_file)
                            checkSuccess "Disabled CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS in the $config_file_requirements config."
                            source $config_file
                        fi
                        break
                        ;;
                    *)
                        echo "Please enter 'y' or 'n'."
                        ;;
                esac
            done
        fi
    fi
}

updateSSHHTMLSSHKeyLinks() 
{
    local index_file="index.html"
    local private_path="${ssh_dir}private/"

    local root_user_key="${CFG_INSTALL_NAME}_sshkey_root"
    local sudo_user_key="${CFG_INSTALL_NAME}_sshkey_${sudo_user_name}"
    local install_user_key="${CFG_INSTALL_NAME}_sshkey_${CFG_DOCKER_INSTALL_USER}"

    if [ -f "$private_path$index_file" ]; then
        # Reset all links to placeholders
        result=$(sudo sed -i "s|<a href=\"$root_user_key\">User - Root's SSH Key</a>|<!--LINK1-->|" $private_path$index_file)
        checkSuccess "Resetting Root URL to empty."

        result=$(sudo sed -i "s|<a href=\"$sudo_user_key\">User - Easydocker's SSH Key</a>|<!--LINK2-->|" $private_path$index_file)
        checkSuccess "Resetting Easydocker URL to empty."

        result=$(sudo sed -i "s|<a href=\"$install_user_key\">User - Dockerinstall's SSH Key</a>|<!--LINK3-->|" $private_path$index_file)
        checkSuccess "Resetting Dockerinstall URL to empty."

        # Check and update links based on the presence of key files
        if [ -f "$private_path$root_user_key" ]; then
            result=$(sudo sed -i "s|<!--LINK1-->|<a href=\"$root_user_key\" download>Download Root's SSH Key</a>|" $private_path$index_file)
            checkSuccess "Root SSH Key found, updating the index.html for download link."
        fi

        if [ -f "$private_path$sudo_user_key" ]; then
            result=$(sudo sed -i "s|<!--LINK2-->|<a href=\"$sudo_user_key\" download>Download Easydocker's SSH Key</a>|" $private_path$index_file)
            checkSuccess "Easydocker SSH Key found, updating the index.html for download link."
        fi

        if [ -f "$private_path$install_user_key" ]; then
            result=$(sudo sed -i "s|<!--LINK3-->|<a href=\"$install_user_key\" download>Download Dockerinstall's SSH Key</a>|" $private_path$index_file)
            checkSuccess "Dockerinstall SSH Key found, updating the index.html for download link."
        fi
    fi
}
