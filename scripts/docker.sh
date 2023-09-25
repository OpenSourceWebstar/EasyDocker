#!/bin/bash

runCommandForDockerInstallUser()
{
    local remote_command="$1"
    
    # Run the SSH command using the existing SSH variables
    result=$(sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command")
}

setupConfigToContainer()
{
    local app_name="$1"
    local flags="$2"
    local target_path="$install_dir$app_name"
    local source_file="$containers_dir$app_name/$app_name.config"

    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi

    if [ -d "$target_path" ]; then
        isNotice "The directory '$target_path' already exists."
    else
        mkdirFolders "$target_path"
    fi
    
    if [ ! -f "$source_file" ]; then
        isError ""Error: "The config file '$source_file' does not exist."
        return 1
    fi
    
    if [ ! -f "$target_path/$app_name.config" ]; then
        copyFile "$source_file" "$target_path/$app_name.config" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
        
        if [ $? -ne 0 ]; then
            isError "Failed to copy the config file to '$target_path'. Check '$docker_log_file' for more details."
            return 1
        else
            isSuccessful "Config file for $app_name has been created"
        fi
    else
        if [[ "$flags" == "install" ]]; then
            # Check if the existing config file exists and has the same content as the source file
            if [ -f "$target_path/$app_name.config" ]; then
                if cmp -s "$source_file" "$target_path/$app_name.config"; then
                    isNotice "Config file for $app_name is already up to date."
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
                                if [ $? -ne 0 ]; then
                                    isError "Failed to copy the config file to '$target_path'. Check '$docker_log_file' for more details."
                                    return 1
                                else
                                    isSuccessful "Config file for $app_name has been updated."
                                fi
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
                if [ $? -ne 0 ]; then
                    isError "Failed to create the config file in '$target_path'. Check '$docker_log_file' for more details."
                    return 1
                else
                    isSuccessful "Config file for $app_name has been created."
                fi
            fi
        fi
    fi

    loadConfigFiles;
}

setupComposeFileNoApp()
{
    local app_name="$1"
    local target_path="$install_dir$app_name"
    local source_file="$containers_dir$app_name/docker-compose.yml"
    
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
    local target_path="$install_dir$app_name"
    local source_file="$containers_dir$app_name/docker-compose.yml"
    
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
    if [[ "$OS" == [123] ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose down")
            checkSuccess "Shutting down container for $app_name"
            
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose up -d")
            checkSuccess "Starting up container for $app_name"

        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then

            result=$(sudo -u $easydockeruser docker-compose down)
            checkSuccess "Shutting down container for $app_name"
            
            result=$(sudo -u $easydockeruser docker-compose up -d)
            checkSuccess "Starting up container for $app_name"
        fi
    else
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then

            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose down")
            checkSuccess "Shutting down container for $app_name"
            
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose up -d")
            checkSuccess "Starting up container for $app_name"

        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then

            result=$(sudo -u $easydockeruser docker-compose down)
            checkSuccess "Shutting down container for $app_name"
            
            result=$(sudo -u $easydockeruser docker-compose up -d)
            checkSuccess "Starting up container for $app_name"

        fi
    fi
}

dockerDownUpAdditionalYML()
{
    local app_name="$1"
    if [[ "$OS" == [123] ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"
            
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q up -d")
            checkSuccess "Starting up container for $app_name (Using additional yml file)"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"
            
            result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q up -d)
            checkSuccess "Starting up container for $app_name (Using additional yml file)"
        fi
    else
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"
            
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q -q up -d")
            checkSuccess "Starting up container for $app_name (Using additional yml file)"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"
            
            result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml up -d)
            checkSuccess "Starting up container for $app_name (Using additional yml file)"
        fi
    fi
}

editComposeFileDefault()
{
    local app_name="$1"
    local compose_file="$install_dir$app_name/docker-compose.yml"
    local config_file="$install_dir$app_name/$app_name.config"
    
    result=$(sudo sed -i \
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
        result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$compose_file")
        checkSuccess "Updating Compose file docker socket for $app_name"
    fi
    
    if [[ "$public" == "true" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            if [[ "$CFG_IPS_WHITELIST" == "" ]]; then
                result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"

                # Loop through compose file
                while IFS= read -r line; do
                    if [[ "$line" == *"#traefik"* && "$line" != *"whitelist"* ]]; then
                        line="${line//#/}"
                    fi
                    echo "$line"
                done < "$compose_file" > >(sudo tee "$compose_file")

                isSuccessful "Enabling Traefik options for public setup, and no whitelist found."
            else
                result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"
                if grep -q "WHITELIST=true" "$config_file"; then
                    result=$(sudo sed -i "s/#traefik/traefik/g" $compose_file)
                    checkSuccess "Enabling Traefik options for public setup and whitelist enabled"
                elif grep -q "WHITELIST=false" "$config_file"; then
                    # Loop through compose file
                    while IFS= read -r line; do
                        if [[ "$line" == *"#traefik"* && "$line" != *"whitelist"* ]]; then
                            line="${line//#/}"
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
            result=$(sudo sed -i '/^labels:/!s/labels:/#labels:/g' "$compose_file")
            checkSuccess "Disable Traefik options for private setup"
        fi
    fi
    
    isSuccessful "Updated the $app_name docker-compose.yml"
}

editComposeFileApp()
{
    local app_name="$1"
    local compose_file="$install_dir$app_name/docker-compose.$app_name.yml"
    local config_file="$install_dir$app_name/$app_name.config"

    result=$(sudo sed -i \
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
        result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$compose_file")
        checkSuccess "Updating Compose file docker socket for $app_name"
    fi
    
    if [[ "$public" == "true" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            if [[ "$CFG_IPS_WHITELIST" == "" ]]; then
                result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"
                result=$(sudo sed -i '/whitelist/!s/#traefik/traefik/g' "$compose_file")
                checkSuccess "Enabling Traefik options for public setup, and no whitelist found."
            else
                result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
                checkSuccess "Enable labels for Traefik option options on public setup"
                if grep -q "WHITELIST=true" "$config_file"; then
                    result=$(sudo sed -i "s/#traefik/traefik/g" $compose_file)
                    checkSuccess "Enabling Traefik options for public setup and whitelist enabled"
                elif grep -q "WHITELIST=false" "$config_file"; then
                    result=$(sudo sed -i '/whitelist/!s/#traefik/traefik/g' "$compose_file")
                    checkSuccess "Enabling Traefik options for public setup, and whitelist disabled."
                fi
            fi
        fi
    fi
    
    if [[ "$public" == "false" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            result=$(sudo sed -i '/^labels:/!s/labels:/#labels:/g' "$compose_file")
            checkSuccess "Disable Traefik options for private setup"
        fi
    fi
    
    isSuccessful "Updated the docker-compose.$app_name.yml"
}

editEnvFileDefault()
{
    local env_file="$install_dir$app_name/.env"
    
    result=$(sudo sed -i \
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
    
    result=$(sudo sed -i \
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
        result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$custompathandfile")
        checkSuccess "Updating Compose file docker socket for $app_name"
    fi
    
    isSuccessful "Updated the $customfile file"
}

setupEnvFile()
{
    result=$(copyFile $install_dir$app_name/env.example $install_dir$app_name/.env)
    checkSuccess "Setting up .env file to path"
}

dockerStopAllApps()
{
    isNotice "Please wait for docker containers to stop"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(runCommandForDockerInstallUser 'docker stop $(docker ps -a -q)')
        checkSuccess "Stopping all docker containers"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo -u $easydockeruser docker stop $(docker ps -a -q))
        checkSuccess "Stopping all docker containers"
    fi
}

dockerStartAllApps()
{
    isNotice "Please wait for docker containers to start"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(runCommandForDockerInstallUser 'docker restart $(docker ps -a -q)')
        checkSuccess "Starting up all docker containers"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo -u $easydockeruser docker restart $(docker ps -a -q))
        checkSuccess "Starting up all docker containers"
    fi
}

dockerAppDown() {
    isNotice "Please wait for $app_name container to stop"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        if [ -d "$install_dir$app_name" ]; then
            result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose down")
            checkSuccess "Shutting down $app_name container"
        else
            isNotice "Directory $install_dir$app_name does not exist. Container not found."
        fi
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        if [ -d "$install_dir$app_name" ]; then
            result=$(cd "$install_dir$app_name" && docker-compose down)
            checkSuccess "Shutting down $app_name container"
        else
            isNotice "Directory $install_dir$app_name does not exist. Container not found."
        fi
    fi
}

dockerAppUp()
{
    local app_name="$1"
    isNotice "Please wait for $app_name container to start"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose up -d")
        checkSuccess "Starting up $app_name container"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(cd $install_dir$app_name && docker-compose up -d)
        checkSuccess "Starting up $app_name container"
    fi
}