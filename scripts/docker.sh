#!/bin/bash

runCommandForDockerInstallUser()
{
    local remote_command="$1"
    
    # Run the SSH command using the existing SSH variables
    result=$(sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command")
}

setupComposeFileNoApp()
{
    local target_path="$install_dir$app_name"
    local source_file="$script_dir/containers/docker-compose.$app_name.yml"
    
    if [ -d "$target_path" ]; then
        isNotice "The directory '$target_path' already exists."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError "The source file '$source_file' does not exist."
        return 1
    fi
    
    mkdirFolders "$target_path"
    if [ $? -ne 0 ]; then
        isError "Failed to create the directory '$target_path'."
        return 1
    fi
    
    copyFile "$source_file" "$target_path/docker-compose.yml" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
    
    cd "$target_path"
}

setupComposeFileApp()
{
    local target_path="$install_dir$app_name"
    local source_file="$script_dir/containers/docker-compose.$app_name.yml"
    
    if [ -d "$target_path" ]; then
        isNotice "The directory '$target_path' already exists."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError ""Error: "The source file '$source_file' does not exist."
        return 1
    fi
    
    result=$(sudo -u $easydockeruser mkdir -p "$target_path")
    checkSuccess "Creating install path for $app_name"
    
    if [ $? -ne 0 ]; then
        isError "Failed to create the directory '$target_path'."
        return 1
    fi
    
    copyFile "$source_file" "$target_path/docker-compose.$app_name.yml" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
    
    cd "$target_path"
}

dockerDownUpDefault()
{
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

dockerUpDownAdditionalYML()
{
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
    local compose_file="$install_dir$app_name/docker-compose.yml"
    
    result=$(sudo sed -i \
        -e "s/DOMAINNAMEHERE/$domain_full/g" \
        -e "s/DOMAINSUBNAMEHERE/$host_setup/g" \
        -e "s/DOMAINPREFIXHERE/$domain_prefix/g" \
        -e "s/PUBLICIPHERE/$public_ip/g" \
        -e "s/IPADDRESSHERE/$ip_setup/g" \
        -e "s/IPWHITELIST/$CFG_IPS_WHITELIST/g" \
        -e "s/PORTHERE/$port/g" \
        -e "s/SECONDPORT/$port_2/g" \
    "$compose_file")
    checkSuccess "Updating Compose file for $app_name"
    
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi
    
    if [[ "$public" == "true" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            result=$(sudo sed -i "s/#traefik/traefik/g" $compose_file)
            checkSuccess "Enabling Traefik options for public setup"
            result=$(sudo sed -i "s/#labels:/labels:/g" $compose_file)
            checkSuccess "Enable labels for Traefik option options on private setup"
        fi
    fi
    
    if [[ "$public" == "false" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            result=$(sudo sed -i "s/labels:/#labels/g" $compose_file)
            checkSuccess "Disable Traefik options for private setup"
        fi
    fi
    
    isSuccessful "Updated the $app_name docker-compose.yml"
}

editComposeFileApp()
{
    local compose_file="$install_dir$app_name/docker-compose.$app_name.yml"
    
    result=$(sudo sed -i \
        -e "s/DOMAINNAMEHERE/$domain_full/g" \
        -e "s/DOMAINSUBNAMEHERE/$host_setup/g" \
        -e "s/DOMAINPREFIXHERE/$domain_prefix/g" \
        -e "s/PUBLICIPHERE/$public_ip/g" \
        -e "s/IPADDRESSHERE/$ip_setup/g" \
        -e "s/IPWHITELIST/$CFG_IPS_WHITELIST/g" \
        -e "s/PORTHERE/$port/g" \
        -e "s/SECONDPORT/$port_2/g" \
    "$compose_file")
    checkSuccess "Updating Compose file for $app_name (Using additional yml file)"
    
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
        "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi
    
    if [[ "$public" == "true" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            result=$(sudo sed -i "s/#traefik/traefik/g" $compose_file)
            checkSuccess "Enabling Traefik options for public setup)"
        fi
    fi
    
    if [[ "$public" == "false" ]]; then
        if [[ "$app_name" != "traefik" ]]; then
            result=$(sudo sed -i "s/labels:/#labels/g" $compose_file)
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
        checkSuccess "Updating Compose file for $app_name"
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