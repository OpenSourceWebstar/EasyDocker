#!/bin/bash

runCommandForDockerInstallUser()
{
    local remote_command="$1"
    
    # Run the SSH command using the existing SSH variables
    local output
    sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command" > /dev/null 2>&1
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        return 0  # Success, command completed without errors
    else
        return 1  # Error, command encountered issues
    fi
}

setupConfigToContainer()
{
    local silent_flag=""
    if [ "$1" == "--silent" ]; then
        silent_flag="$1"
        shift
    fi

    local app_name="$1"
    local flags="$2"
    local target_path="$containers_dir$app_name"
    local source_file="$install_containers_dir$app_name/$app_name.config"

    #echo "setupConfigToContainer"
    #echo "app_name = $app_name"
    #echo "silent_flag = $silent_flag"
    #echo "flags = $flags"
    #echo "target_path = $target_path"
    #echo "source_file = $source_file"

    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi

    if [ -d "$target_path" ]; then
        if [ -z "$silent_flag" ]; then
            isNotice "The directory '$target_path' already exists."
        fi
    else
        if [ -z "$silent_flag" ]; then
            mkdirFolders "$target_path"
        else
            mkdirFolders "$silent_flag" "$target_path"
        fi
    fi

    if [ ! -f "$source_file" ]; then
        isError "The config file '$source_file' does not exist."
        return 1
    fi

    if [ ! -f "$target_path/$app_name.config" ]; then
        if [ -z "$silent_flag" ]; then
            isNotice "Copying config file to '$target_path/$app_name.config'..."
            copyFile "$source_file" "$target_path/$app_name.config" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
        else
            copyFile "$silent_flag" "$source_file" "$target_path/$app_name.config" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
        fi
    fi

    if [[ "$flags" == "install" ]]; then
        if [ -f "$target_path/$app_name.config" ]; then
            # Same content check
            if cmp -s "$source_file" "$target_path/$app_name.config"; then
                echo ""
                isNotice "Config file for $app_name contains no edits."
                echo ""
                while true; do
                    isQuestion "Would you like to make edits to the config file? (y/n): "
                    read -rp "" editconfigaccept
                    echo ""
                    case $editconfigaccept in
                        [yY])
                            # Calculate the checksum of the original file
                            local original_checksum=$(md5sum "$target_path/$app_name.config")

                            # Open the file with nano for editing
                            sudo nano "$target_path/$app_name.config"

                            # Calculate the checksum of the edited file
                            local edited_checksum=$(md5sum "$target_path/$app_name.config")

                            # Compare the checksums to check if changes were made
                            if [[ "$original_checksum" != "$edited_checksum" ]]; then
                                isSuccessful "Changes have been made to the $app_name.config."
                            fi
                            break
                            ;;
                        [nN])
                            break  # Exit the loop without updating
                            ;;
                        *)
                            isNotice "Please provide a valid input (y or n)."
                            ;;
                    esac
                done
            else
                echo ""
                isNotice "Config file for $app_name has been updated..."
                echo ""
                while true; do
                    isQuestion "Would you like to reset the config file? (y/n): "
                    read -rp "" resetconfigaccept
                    echo ""
                    case $resetconfigaccept in
                        [yY])
                            isNotice "Resetting $app_name config file."
                            copyFile "$source_file" "$target_path/$app_name.config" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
                            break  # Exit the loop after executing whitelistAndStartApp
                            ;;
                        [nN])
                            break  # Exit the loop without updating
                            ;;
                        *)
                            isNotice "Please provide a valid input (y or n)."
                            ;;
                    esac
                done
            fi
        else
            isNotice "Config file for $app_name does not exist. Creating it..."
            copyFile "$source_file" "$target_path/$app_name.config" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
            echo ""
            isNotice "Config file for $app_name contains no edits."
            echo ""
            while true; do
                isQuestion "Would you like to make edits to the config file? (y/n): "
                read -rp "" editconfigaccept
                echo ""
                case $editconfigaccept in
                    [yY])
                        # Calculate the checksum of the original file
                        local original_checksum=$(md5sum "$target_path/$app_name.config")

                        # Open the file with nano for editing
                        sudo nano "$target_path/$app_name.config"

                        # Calculate the checksum of the edited file
                        local edited_checksum=$(md5sum "$target_path/$app_name.config")

                        # Compare the checksums to check if changes were made
                        if [[ "$original_checksum" != "$edited_checksum" ]]; then
                            isSuccessful "Changes have been made to the $app_name.config."
                        fi
                        break
                        ;;
                    [nN])
                        break  # Exit the loop without updating
                        ;;
                    *)
                        isNotice "Please provide a valid input (y or n)."
                        ;;
                esac
            done
        fi
    fi

    loadFiles "app_configs";
}

setupComposeFileNoApp()
{
    local app_name="$1"
    local target_path="$containers_dir$app_name"
    local source_file="$install_containers_dir$app_name/docker-compose.yml"
    
    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError "The source file '$source_file' does not exist."
        return 1
    fi
    
    copyFile "$source_file" "$target_path/docker-compose.yml" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
}

setupComposeFileApp()
{
    local app_name="$1"
    local target_path="$containers_dir$app_name"
    local source_file="$install_containers_dir$app_name/docker-compose.yml"
    
    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError ""Error: "The source file '$source_file' does not exist."
        return 1
    fi
    
    copyFile "$source_file" "$target_path/docker-compose.$app_name.yml" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
}

dockerDownUpDefault()
{
    local app_name="$1"
    if [[ "$OS" == [1234567] ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
            checkSuccess "Shutting down container for $app_name"

            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose up -d")
            checkSuccess "Started container for $app_name"

        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then

            local result=$(sudo -u $easydockeruser docker-compose down)
            checkSuccess "Shutting down container for $app_name"

            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(sudo -u $easydockeruser docker-compose up -d)
            checkSuccess "Started container for $app_name"
        fi
    else
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then

            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
            checkSuccess "Shutting down container for $app_name"
            
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose up -d")
            checkSuccess "Started container for $app_name"

        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then

            local result=$(sudo -u $easydockeruser docker-compose down)
            checkSuccess "Shutting down container for $app_name"
            
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(sudo -u $easydockeruser docker-compose up -d)
            checkSuccess "Started container for $app_name"

        fi
    fi
}

dockerDownUpAdditionalYML()
{
    local app_name="$1"
    if [[ "$OS" == [1234567] ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"

            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q up -d")
            checkSuccess "Started container for $app_name (Using additional yml file)"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            local result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"
            
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q up -d)
            checkSuccess "Started container for $app_name (Using additional yml file)"
        fi
    else
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"
            
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q -q up -d")
            checkSuccess "Started container for $app_name (Using additional yml file)"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            local result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"

            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
            checkSuccess "Started container for $app_name (Using additional yml file)"
        fi
    fi
}

editComposeFileDefault()
{
    local app_name="$1"
    local compose_file="$containers_dir$app_name/docker-compose.yml"
    local config_file="$containers_dir$app_name/$app_name.config"
    
    local result=$(sudo sed -i \
        -e "s/DOMAINNAMEHERE/$domain_full/g" \
        -e "s/DOMAINSUBNAMEHERE/$host_setup/g" \
        -e "s/DOMAINPREFIXHERE/$domain_prefix/g" \
        -e "s/PUBLICIPHERE/$public_ip/g" \
        -e "s/IPADDRESSHERE/$ip_setup/g" \
        -e "s/PORTHERE/$port/g" \
        -e "s/SECONDPORT/$port_2/g" \
    "$compose_file")
    checkSuccess "Updating Compose file for $app_name"
    
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$compose_file")
        checkSuccess "Updating Compose file docker socket for $app_name"
    fi
    
    if [[ "$public" == "true" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            if [[ "$CFG_IPS_WHITELIST" == "" ]]; then
                local result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"

                # Loop through compose file
                while IFS= read -r line; do
                    if [[ "$line" == *"#traefik"* && "$line" != *"whitelist"* ]]; then
                        local line="${line//#/}"
                    fi
                    echo "$line"
                done < "$compose_file" > >(sudo tee "$compose_file")

                isSuccessful "Enabling Traefik options for public setup, and no whitelist found."
            else
                local result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"
                if grep -q "WHITELIST=true" "$config_file"; then
                    local result=$(sudo sed -i "s/#traefik/traefik/g" $compose_file)
                    checkSuccess "Enabling Traefik options for public setup and whitelist enabled"
                elif grep -q "WHITELIST=false" "$config_file"; then
                    # Loop through compose file
                    while IFS= read -r line; do
                        if [[ "$line" == *"#traefik"* && "$line" != *"whitelist"* ]]; then
                            local line="${line//#/}"
                        fi
                        echo "$line"
                    done < "$compose_file" > >(sudo tee "$compose_file")
                    isSuccessful "Enabling Traefik options for public setup, and no whitelist found."
                fi
            fi
        fi
    fi
    
    if [[ "$public" == "false" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            local result=$(sudo sed -i '/^labels:/!s/labels:/#labels:/g' "$compose_file")
            checkSuccess "Disable Traefik options for private setup"
        fi
    fi
    
    isSuccessful "Updated the $app_name docker-compose.yml"
}

editComposeFileApp()
{
    local app_name="$1"
    local compose_file="$containers_dir$app_name/docker-compose.$app_name.yml"
    local config_file="$containers_dir$app_name/$app_name.config"

    local result=$(sudo sed -i \
        -e "s/DOMAINNAMEHERE/$domain_full/g" \
        -e "s/DOMAINSUBNAMEHERE/$host_setup/g" \
        -e "s/DOMAINPREFIXHERE/$domain_prefix/g" \
        -e "s/PUBLICIPHERE/$public_ip/g" \
        -e "s/IPADDRESSHERE/$ip_setup/g" \
        -e "s/PORTHERE/$port/g" \
        -e "s/SECONDPORT/$port_2/g" \
    "$compose_file")
    checkSuccess "Updating Compose file for $app_name (Using additional yml file)"
    
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$compose_file")
        checkSuccess "Updating Compose file docker socket for $app_name"
    fi
    
    if [[ "$public" == "true" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            if [[ "$CFG_IPS_WHITELIST" == "" ]]; then
                local result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"
                local result=$(sudo sed -i '/whitelist/!s/#traefik/traefik/g' "$compose_file")
                checkSuccess "Enabling Traefik options for public setup, and no whitelist found."
            else
                local result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"
                if grep -q "WHITELIST=true" "$config_file"; then
                    local result=$(sudo sed -i "s/#traefik/traefik/g" $compose_file)
                    checkSuccess "Enabling Traefik options for public setup and whitelist enabled"
                elif grep -q "WHITELIST=false" "$config_file"; then
                    local result=$(sudo sed -i '/whitelist/!s/#traefik/traefik/g' "$compose_file")
                    checkSuccess "Enabling Traefik options for public setup, and whitelist disabled."
                fi
            fi
        fi
    fi
    
    if [[ "$public" == "false" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            local result=$(sudo sed -i '/^labels:/!s/labels:/#labels:/g' "$compose_file")
            checkSuccess "Disable Traefik options for private setup"
        fi
    fi
    
    isSuccessful "Updated the docker-compose.$app_name.yml"
}

editEnvFileDefault()
{
    local env_file="$containers_dir$app_name/.env"
    
    local result=$(sudo sed -i \
        -e "s/DOMAINNAMEHERE/$domain_full/g" \
        -e "s/DOMAINSUBNAMEHERE/$host_setup/g" \
        -e "s/DOMAINPREFIXHERE/$domain_prefix/g" \
        -e "s/PUBLICIPHERE/$public_ip/g" \
        -e "s/IPADDRESSHERE/$ip_setup/g" \
        -e "s/IPWHITELIST/$CFG_IPS_WHITELIST/g" \
        -e "s/PORTHERE/$port/g" \
        -e "s/SECONDPORT/$port_2/g" \
    "$env_file")
    checkSuccess "Updating .env file for $app_name"
    
    isSuccessful "Updated the .env file"
}

editCustomFile()
{
    local customfile="$1"
    local custompath="$2"
    local custompathandfile="$custompath/$customfile"
    
    local result=$(sudo sed -i \
        -e "s/DOMAINNAMEHERE/$domain_full/g" \
        -e "s/DOMAINSUBNAMEHERE/$host_setup/g" \
        -e "s/DOMAINPREFIXHERE/$domain_prefix/g" \
        -e "s/PUBLICIPHERE/$public_ip/g" \
        -e "s/IPADDRESSHERE/$ip_setup/g" \
        -e "s/IPWHITELIST/$CFG_IPS_WHITELIST/g" \
        -e "s/PORTHERE/$port/g" \
        -e "s/SECONDPORT/$port_2/g" \
    "$custompathandfile")
    checkSuccess "Updating $customfile file for $app_name"
    
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$custompathandfile")
        checkSuccess "Updating Compose file docker socket for $app_name"
    fi
    
    isSuccessful "Updated the $customfile file"
}

setupEnvFile()
{
    local result=$(copyFile $containers_dir$app_name/env.example $containers_dir$app_name/.env)
    checkSuccess "Setting up .env file to path"
}

dockerStopAllApps()
{
    isNotice "Please wait for docker containers to stop"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local result=$(runCommandForDockerInstallUser 'docker stop $(docker ps -a -q)')
        checkSuccess "Stopping all docker containers"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        local result=$(sudo -u $easydockeruser docker stop $(docker ps -a -q))
        checkSuccess "Stopping all docker containers"
    fi
}

dockerStartAllApps()
{
    isNotice "Please wait for docker containers to start"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local result=$(runCommandForDockerInstallUser 'docker restart $(docker ps -a -q)')
        checkSuccess "Starting up all docker containers"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        local result=$(sudo -u $easydockeruser docker restart $(docker ps -a -q))
        checkSuccess "Starting up all docker containers"
    fi
}

dockerAppDown() 
{
    local app_name="$1"

    isNotice "Please wait for $app_name container to stop"

    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        if [ -d "$containers_dir$app_name" ]; then
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
            checkSuccess "Shutting down $app_name container"
        else
            isNotice "Directory $containers_dir$app_name does not exist. Container not found."
        fi
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        if [ -d "$containers_dir$app_name" ]; then
            local result=$(cd "$containers_dir$app_name" && docker-compose down)
            checkSuccess "Shutting down $app_name container"
        else
            isNotice "Directory $containers_dir$app_name does not exist. Container not found."
        fi
    fi
}

dockerAppUp()
{
    local app_name="$1"

    isNotice "Please wait for $app_name container to start"

    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose up -d")
        checkSuccess "Starting up $app_name container"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        local result=$(cd $containers_dir$app_name && docker-compose up -d)
        checkSuccess "Starting up $app_name container"
    fi
}