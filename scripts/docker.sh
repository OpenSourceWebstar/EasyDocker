#!/bin/bash

runCommandForDocker() 
{
    local command="$1"
    local type="$2" # sudo

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        runCommandForDockerInstallUser "$command"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
        if [[ $type == "sudo" ]]; then
            sudo $command
        else
            $command
        fi
    fi
}

runCommandForDockerInstallUser() 
{
    local silent_flag=""
    if [ "$1" == "--silent" ]; then
        silent_flag="$1"
        shift
    fi
    local remote_command="$1"

    # Get the value of PasswordAuthentication from sshd_config
    local result=$(sudo sed -i '/#PasswordAuthentication/d' $sshd_config)
    local passwordAuth=$(grep -i "^PasswordAuthentication" $sshd_config | awk '{print $2}')

    # Keys
    local private_path="${ssh_dir}private/"
    local install_user_key="${CFG_INSTALL_NAME}_sshkey_${CFG_DOCKER_INSTALL_USER}"

    # Run the SSH command using the existing SSH variables
    local output
    if [ "$passwordAuth" == "no" ]; then
        if [ -z "$silent_flag" ]; then
            ssh -i "${private_path}${install_user_key}" -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command"
        else
            ssh -i "${private_path}${install_user_key}" -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command" > /dev/null 2>&1
        fi
    else
        if [ -z "$silent_flag" ]; then
            sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command"
        else
            sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command" > /dev/null 2>&1
        fi
    fi

    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        return 0  # Success, command completed without errors
    else
        return 1  # Error, command encountered issues
    fi
}

setupConfigToContainer()
{
    local silent_flag="$1"
    local app_name="$2"
    local flags="$3"

    local target_path="$containers_dir$app_name"
    local source_file="$install_containers_dir$app_name/$app_name.config"
    local config_file="$app_name.config"

    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi

    if [ -d "$target_path" ]; then
        if [ "$silent_flag" == "loud" ]; then
            isNotice "The directory '$target_path' already exists."
        fi
    else
        mkdirFolders "$silent_flag" "$CFG_DOCKER_INSTALL_USER" "$target_path"
    fi

    if [ ! -f "$source_file" ]; then
        isError "The config file '$source_file' does not exist."
        return 1
    fi

    if [ ! -f "$target_path/$config_file" ]; then
        if [ "$silent_flag" == "loud" ]; then
            isNotice "Copying config file to '$target_path/$config_file'..."
        fi
        copyFile "$silent_flag" "$source_file" "$target_path/$config_file" $sudo_user_name | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1
    fi

    fixConfigPermissions $silent_flag $app_name;

    # Check if the file exists
    if [ ! -e "$target_path/$config_file" ]; then
        isError "File $target_path/$config_file does not exist"
        return
    fi

    # Check if the user has read permission on target_path/config_file
    if [ ! -r "$target_path/$config_file" ]; then
        isError "Insufficient permissions to read $target_path/$config_file"
        return
    fi

    if [[ "$flags" == "install" ]]; then
        if [ -f "$target_path/$config_file" ]; then
            # Same content check
            if sudo cmp -s "$source_file" "$target_path/$config_file"; then
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
                            local original_checksum=$(sudo md5sum "$target_path/$config_file")

                            # Open the file with $CFG_TEXT_EDITOR for editing
                            sudo $CFG_TEXT_EDITOR "$target_path/$config_file"

                            # Calculate the checksum of the edited file
                            local edited_checksum=$(sudo md5sum "$target_path/$config_file")

                            # Compare the checksums to check if changes were made
                            if [[ "$original_checksum" != "$edited_checksum" ]]; then
                                source $target_path/$config_file
                                setupInstallVariables $app_name;
                                isSuccessful "Changes have been made to the $config_file."
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
                            copyFile "loud" "$source_file" "$target_path/$config_file" $CFG_DOCKER_INSTALL_USER | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1
                            source $target_path/$config_file
                            setupConfigToContainer "loud" $app_name;
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
        else
            isNotice "Config file for $app_name does not exist. Creating it..."
            copyFile "loud" "$source_file" "$target_path/$config_file" $CFG_DOCKER_INSTALL_USER | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1
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
                        local original_checksum=$(sudo md5sum "$target_path/$config_file")

                        # Open the file with $CFG_TEXT_EDITOR for editing
                        sudo $CFG_TEXT_EDITOR "$target_path/$config_file"

                        # Calculate the checksum of the edited file
                        local edited_checksum=$(sudo md5sum "$target_path/$config_file")

                        # Compare the checksums to check if changes were made
                        if [[ "$original_checksum" != "$edited_checksum" ]]; then
                            source $target_path/$config_file
                            setupInstallVariables $app_name;
                            isSuccessful "Changes have been made to the $config_file."
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

    scanFileForRandomPassword "$target_path/$config_file";
    loadFiles "app_configs";
}

checkAllowedInstall() 
{
    local app_name="$1"

    #if [ "$status" == "installed" ]; then
    #elif [ "$status" == "running" ]; then
    #elif [ "$status" == "not_installed" ]; then
    #elif [ "$status" == "invalid_flag" ]; then

    case "$app_name" in
        "wireguard")
            # Check if WireGuard is already installed and load params
            if [[ -e /etc/wireguard/params ]]; then
                isError "Virtualmin is installed, this will conflict with $app_name."
                isError "Installation is now aborting..."
                uninstallApp "$app_name"
                return 1
            fi
            ;;
        #"mailcow")
            #local status=$(checkAppInstalled "webmin" "linux" "check_active")
            #if [ "$status" == "installed" ]; then
                #isError "Virtualmin is installed, this will conflict with $app_name."
                #isError "Installation is now aborting..."
                #uninstallApp "$app_name"
                #return 1
            #elif [ "$status" == "running" ]; then
                #isError "Virtualmin is installed, this will conflict with $app_name."
                #isError "Installation is now aborting..."
                #uninstallApp "$app_name"
                #return 1
            #fi
            #;;
        #"virtualmin")
            #local status=$(checkAppInstalled "webmin" "linux" "check_active")
            #if [ "$status" == "not_installed" ]; then
              #isError "Virtualmin is not installed or running, it is required."
              #uninstallApp "$app_name"
              #return 1
            #elif [ "$status" == "invalid_flag" ]; then
              #isError "Invalid flag provided..cancelling install..."
              #uninstallApp "$app_name"
              #return 1
            #fi
            #local status=$(checkAppInstalled "traefik" "docker")
            #if [ "$status" == "not_installed" ]; then
                #while true; do
                    #echo ""
                    #isNotice "Traefik is not installed, it is required."
                    #echo ""
                    #isQuestion "Would you like to install Traefik? (y/n): "
                    #read -p "" virtualmin_traefik_choice
                    #if [[ -n "$virtualmin_traefik_choice" ]]; then
                        #break
                    #fi
                    #isNotice "Please provide a valid input."
                #done
                #if [[ "$virtualmin_traefik_choice" == [yY] ]]; then
                    #installApp traefik;
                #fi
                #if [[ "$virtualmin_traefik_choice" == [nN] ]]; then
                    #isError "Installation is now aborting..."
                    #uninstallApp "$app_name"
                    #return 1
                #fi
            #elif [ "$status" == "invalid_flag" ]; then
              #isError "Invalid flag provided..cancelling install..."
              #uninstallApp "$app_name"
              #return 1
            #fi
            #;;
    esac

    isSuccessful "Application is allowed to be installed."
}

checkAppInstalled() 
{
    local app_name="$1"
    local flag="$2"
    local check_active="$3"
    local package_status=""

    if [ "$flag" = "linux" ]; then
        if dpkg -l | grep -q "$app_name"; then
            package_status="installed"
            if [ "$check_active" = "check_active" ]; then
                if systemctl is-active --quiet "$app_name"; then
                    package_status="running"
                fi
            fi
        else
            package_status="not_installed"
        fi
    elif [ "$flag" = "docker" ]; then
        if [ -f "$docker_dir/$db_file" ]; then
            results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
        fi 
        if [ -n "$results" ]; then
            package_status="installed"
        else
            package_status="not_installed"
        fi
    else
        package_status="invalid_flag"
    fi

    echo "$package_status"
}

installApp()
{
    local app_name="$1"
    local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
    local installFuncName="install${app_name_ucfirst}"

    # Create a variable with the name of $app_name and set its value to "i"
    declare "${app_name}=i"

    # Call the installation function
    ${installFuncName}
}

restartApp()
{
    local app_name="$1"
    local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
    local installFuncName="install${app_name_ucfirst}"

    # Create a variable with the name of $app_name and set its value to "i"
    declare "${app_name}=r"

    # Call the installation function
    ${installFuncName}
}

setupComposeFile()
{
    local app_name="$1"
    local custom_file="$2"
    local custom_path="$3"

    # Source Filenames
    if [[ $custom_file == "" ]]; then
        local source_compose_file="docker-compose.yml";
    elif [[ $custom_file != "" ]]; then
        local source_compose_file="$custom_file";
    fi

    if [[ $custom_path == "" ]]; then
        local source_path="$install_containers_dir$app_name"
    elif [[ $custom_path != "" ]]; then
        local source_path="$install_containers_dir$app_name/$custom_path/"
    fi

    local source_file="$source_path/$source_compose_file"

    # Target Filenames
    if [[ $compose_setup == "default" ]]; then
        local target_compose_file="docker-compose.yml";
    elif [[ $compose_setup == "app" ]]; then
        local target_compose_file="docker-compose.$app_name.yml";
    fi

    local target_path="$containers_dir$app_name"
    local target_file="$target_path/$target_compose_file"


    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError "The source file '$source_file' does not exist."
        return 1
    fi
    
    copyFile "loud" "$source_file" "$target_file" $CFG_DOCKER_INSTALL_USER | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
}

dockerDownUp()
{
    local app_name="$1"

    dockerDown $app_name;
    dockerUp $app_name;
}

dockerDown()
{
    local app_name="$1"
    local custom_compose="$2"
    # Compose file public variable for restarting etc
    if [[ $compose_setup == "default" ]]; then
        local setup_compose="-f docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local setup_compose="-f docker-compose.yml -f docker-compose.$app_name.yml"
    fi
    if [[ $custom_compose != "" ]]; then
        local setup_compose="-f docker-compose.yml -f $custom_compose"
    fi

    if [[ "$OS" == [1234567] ]]; then
        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose down")
            checkSuccess "Shutting down container for $app_name"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
            local result=$(cd $containers_dir$app_name && sudo docker-compose $setup_compose down)
            checkSuccess "Shutting down container for $app_name"
        fi
    else
        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose down")
            checkSuccess "Shutting down container for $app_name"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
            local result=$(cd $containers_dir$app_name && sudo docker-compose $setup_compose down)
            checkSuccess "Shutting down container for $app_name"
        fi
    fi
}

dockerUp()
{
    local app_name="$1"
    local custom_compose="$2"
    # Compose file public variable for restarting etc
    if [[ $compose_setup == "default" ]]; then
        local setup_compose="-f docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local setup_compose="-f docker-compose.yml -f docker-compose.$app_name.yml"
    fi
    if [[ $custom_compose != "" ]]; then
        local setup_compose="-f docker-compose.yml -f $custom_compose"
    fi

    if [[ "$OS" == [1234567] ]]; then
        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose up -d")
            checkSuccess "Started container for $app_name"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(cd $containers_dir$app_name && sudo docker-compose up -d)
            checkSuccess "Started container for $app_name"
        fi
    else
        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose $setup_compose up -d")
            checkSuccess "Started container for $app_name"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
            isNotice "Starting container for $app_name, this may take a while..."
            local result=$(cd $containers_dir$app_name && sudo docker-compose $setup_compose up -d)
            checkSuccess "Started container for $app_name"
        fi
    fi
}

dockerUpdateAndStartApp()
{
    local app_name="$1"
    local flags="$2"
    local norestart="$3"

    # Starting variable for app
    clearAllPortData;
    setupScanVariables $app_name;

    # Always keep YML updated
    dockerUpdateCompose $app_name $flags $norestart;
}

dockerScan()
{
    echo ""
    echo "#####################################"
    echo "###     Whitelist/Port Updater    ###"
    echo "#####################################"
    echo ""
    for app_name_dir in "$containers_dir"/*/; do
        if [ -d "$app_name_dir" ]; then
            local app_name=$(basename "$app_name_dir")

            # Starting variable for app
            clearAllPortData;
            setupScanVariables $app_name;
    
            # Always keep YML updated
            dockerUpdateCompose $app_name scan;

            # Update ports for the app
            checkAppPorts $app_name scan;
        fi
    done

    dockerUpdateTraefikWhitelist;
    handleAllConflicts;
    isSuccessful "All application whitelists are up to date."
}

dockerUpdateTraefikWhitelist() 
{
    local whitelist_file="${containers_dir}traefik/etc/dynamic/whitelist.yml"
    if [ -f "$whitelist_file" ]; then
        # Split the CFG_IPS_WHITELIST into an array
        IFS=',' read -ra IP_ARRAY <<< "$CFG_IPS_WHITELIST"

        # Build the YAML content dynamically
        YAML_CONTENT="http:
  middlewares:
    global-ipwhitelist:
      ipWhiteList:
        sourceRange:"

        for IP in "${IP_ARRAY[@]}"; do
            YAML_CONTENT+="\n          - \"$IP\""
        done

        # Now update the YAML file with the new content using sudo
        echo -e "$YAML_CONTENT" | sudo tee "$whitelist_file" > /dev/null
        isSuccessful "Traefik has been updated with the latest whitelist IPs."
    fi
}

dockerUpdateCompose()
{
    local app_name="$1"
    local flags="$2"
    local norestart="$3"

    local whitelistupdates=false
    local timezoneupdates=false

    if [[ $compose_setup == "default" ]]; then
        local compose_file="docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local compose_file="docker-compose.$app_name.yml"
    fi

    # Whitelist update for yml files
    for yaml_file in "$containers_dir/$app_name"/$compose_file; do
        if [ -f "$yaml_file" ]; then
            # This is for updating Timzeones
            if sudo grep -q " TZ=" "$yaml_file"; then
                if sudo grep -q " TZ=TIMEZONEHERE" "$yaml_file"; then
                    local result=$(sudo sed -i "s| TZ=TIMEZONEHERE| TZ=$CFG_TIMEZONE|" "$yaml_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    local timezoneupdates=true
                    break  # Exit the loop after updating
                fi
                # If the timzones are setup already but need an update
                local current_timezone=""
                local current_timezone=$(grep " TZ=" "$yaml_file" | cut -d '=' -f 2 | xargs)
                if [ "$current_timezone" != "$CFG_TIMEZONE" ] && [ "$current_timezone" != "TIMEZONEHERE" ]; then
                    local result=$(sudo sed -i "s| TZ=$current_timezone| TZ=$CFG_TIMEZONE|" "$yaml_file")
                    checkSuccess "Update the Timezone for $app_name"
                    local timezoneupdates=true
                fi
            fi
        fi
    done

    # Fail2ban specifics
    if [[ "$app_name" == "fail2ban" ]]; then
        local jail_local_file="$containers_dir/$app_name/config/$app_name/jail.local"
        
        if [ -f "$jail_local_file" ]; then
            if sudo grep -q "ignoreip = ips_whitelist" "$jail_local_file"; then

                # Whitelist not set up yet
                if sudo grep -q "ignoreip = ips_whitelist" "$yaml_file"; then
                    local result=$(sudo sed -i "s/ips_whitelist/$CFG_IPS_WHITELIST/" "$jail_local_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    local whitelistupdates=true
                fi

                # If the IPs are set up already but need an update
                local current_ip_range=$(grep "ignoreip = " "$jail_local_file" | cut -d ' ' -f 2)
                if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                    local result=$(sudo sed -i "s/ignoreip = ips_whitelist/ignoreip = $CFG_IPS_WHITELIST/" "$jail_local_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    local whitelistupdates=true
                fi
            fi
        fi
    fi

    if [ "$flags" == "install" ]; then
        setupFileWithConfigData $app_name;
        if [[ $norestart != "norestart" ]]; then
            dockerUpdateRestart $app_name $flags;
        fi
        if [ "$timezoneupdates" == "true" ]; then
            if [ "$did_not_restart" == "true" ]; then
                isSuccessful "The timezone for $app_name is now up to date."
                isNotice "Please restart $app_name to apply any updates."
            else
                isSuccessful "The timezone for $app_name is now up to date and restarted."
            fi
        fi
        local timezoneupdates=false
        did_not_restart=false
    fi

    if [ "$flags" == "scan" ]; then
        if [ "$timezoneupdates" == "true" ]; then
            if [ "$did_not_restart" == "true" ]; then
                isSuccessful "The timezone for $app_name is now up to date."
                isNotice "Please restart $app_name to apply any updates."
            else
                isSuccessful "The timezone for $app_name is now up to date and restarted."
            fi
        fi
        local timezoneupdates=false
        did_not_restart=false
    fi

    if [ "$flags" == "restart" ]; then
        setupFileWithConfigData $app_name;
        if [[ $norestart != "norestart" ]]; then
            dockerUpdateRestart $app_name $flags;
        fi
    fi
}

dockerUpdateRestart()
{
    local app_name="$1"
    local flags="$2"

    if [[ $flags == "install" ]] ; then
        dockerDownUp $app_name;
        did_not_restart=false
    elif [[ $flags == "" ]] || [[ $flags == "restart" ]]; then
        while true; do
            echo ""
            isNotice "Changes have been made to the $app_name configuration."
            echo ""
            isQuestion "Would you like to restart $app_name? (y/n): "
            echo ""
            read -p "" restart_choice
            if [[ -n "$restart_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$restart_choice" == [yY] ]]; then
            dockerDownUp $app_name;
            did_not_restart=false
        fi
        if [[ "$restart_choice" == [nN] ]]; then
            did_not_restart=true
        fi
    fi
}

setupFileWithConfigData()
{
    local app_name="$1"
    local custom_file="$2"
    local custom_path="$3"

    if [[ $compose_setup == "default" ]]; then
        local file_name="docker-compose.yml";
    elif [[ $compose_setup == "app" ]]; then
        local file_name="docker-compose.$app_name.yml";
    fi

    if [[ $custom_file != "" ]]; then
        local file_name="$custom_file"
    fi

    if [[ $custom_path == "" ]]; then
        local file_path="$containers_dir$app_name"
    elif [[ $custom_path != "" ]]; then
        local file_path="$containers_dir$app_name/$custom_path/"
    fi

    local full_file_path="$file_path/$file_name"

    local result=$(sudo sed -i \
        -e "s|DOMAINNAMEHERE|$domain_full|g" \
        -e "s|DOMAINSUBNAMEHERE|$host_setup|g" \
        -e "s|DOMAINPREFIXHERE|$domain_prefix|g" \
        -e "s|PUBLICIPHERE|$public_ip_v4|g" \
        -e "s|IPADDRESSHERE|$ip_setup|g" \
        -e "s|PORT1|$usedport1|g" \
        -e "s|PORT2|$usedport2|g" \
        -e "s|PORT3|$usedport3|g" \
        -e "s|PORT4|$usedport4|g" \
        -e "s|TIMEZONEHERE|$CFG_TIMEZONE|g" \
        -e "s|EMAILHERE|$CFG_EMAIL|g" \
        -e "s|DOCKERNETWORK|$CFG_NETWORK_NAME|g" \
        -e "s|MTUHERE|$CFG_NETWORK_MTU|g" \
    "$full_file_path")
    checkSuccess "Updating $file_name for $app_name"
    
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
            -e "s|DOCKERINSTALLUSERID|$docker_install_user_id|g" \
            -e "s|UIDHERE|$docker_install_user_id|g" \
            -e "s|GIDHERE|$docker_install_user_id|g" \
        "$full_file_path")
        checkSuccess "Updating docker socket for $app_name"
    fi

    if [[ $file_name == *"docker-compose"* ]]; then
        if [[ "$public" == "true" ]]; then    
            setupTraefikLabels $app_name $full_file_path;
        fi
        
        if [[ "$public" == "false" ]]; then
            if ! grep -q "#labels:" "$full_file_path"; then
                local result=$(sudo sed -i 's/labels:/#labels:/g' "$full_file_path")
                checkSuccess "Disable Traefik options for private setup"
            fi
            local result=$(sudo sed -i \
                -e "s|0.0.0.0:|127.0.0.1:|g" \
            "$full_file_path")
            checkSuccess "Updating $file_name for $app_name"
        fi
    fi

    scanFileForRandomPassword $full_file_path;
    
    isSuccessful "Updated the $app_name docker-compose.yml"
}

scanFileForRandomPassword()
{
    local file="$1"
    
    if [ -f "$file" ]; then
        # Check if the file contains the placeholder string "RANDOMIZEDPASSWORD"
        while sudo grep  -q "RANDOMIZEDPASSWORD" "$file"; do
            # Generate a unique random password
            local random_password=$(openssl rand -base64 12 | tr -d '+/=')
            
            # Capture the content before "RANDOMIZEDPASSWORD"
            local config_content=$(sudo sed -n "s/.*RANDOMIZEDPASSWORD \(.*\)/\1/p" "$file")

            # Update the first occurrence of "RANDOMIZEDPASSWORD" with the new password
            sudo sed -i "0,/\(RANDOMIZEDPASSWORD\)/s//${random_password}/" "$file"
            
            # Display the update message with the captured content and file name
            isSuccessful "Updated $config_content in $(basename "$file") with a new password."
        done
    fi
}

setupEnvFile()
{
    local result=$(copyFile "loud" $containers_dir$app_name/env.example $containers_dir$app_name/.env $CFG_DOCKER_INSTALL_USER)
    checkSuccess "Setting up .env file to path"
}

dockerStopAllApps()
{
    local type="$1"

    isNotice "Please wait for docker containers to stop"
    
    if [[ $type == "rootless" ]]; then
        local result=$(runCommandForDockerInstallUser 'docker ps -q 2>/dev/null')
        if [[ -n "$result" ]]; then
            local result=$(runCommandForDockerInstallUser 'docker stop $(docker ps -a -q)')
            checkSuccess "Stopping all docker containers (Rootless if installed)"
        fi
    fi

    if [[ $type == "root" ]]; then
        local result=$(sudo docker ps -q 2>/dev/null)
        if [[ -n "$result" ]]; then
            local result=$(sudo docker stop $(docker ps -a -q))
            checkSuccess "Stopping all docker containers (Rooted if installed)"
        fi
    fi
}

dockerStartAllApps()
{
    isNotice "Please wait for docker containers to start"
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local result=$(runCommandForDockerInstallUser 'docker restart $(docker ps -a -q)')
        checkSuccess "Starting up all docker containers"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
        local result=$(sudo docker restart $(docker ps -a -q))
        checkSuccess "Starting up all docker containers"
    fi
}

dockerAppDown() 
{
    local app_name="$1"

    isNotice "Please wait for $app_name container to stop"

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        if [ -d "$containers_dir$app_name" ]; then
            local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down")
            checkSuccess "Shutting down $app_name container"
        else
            isNotice "Directory $containers_dir$app_name does not exist. Container not found."
        fi
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
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

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose up -d")
        checkSuccess "Starting up $app_name container"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
        local result=$(cd $containers_dir$app_name && docker-compose up -d)
        checkSuccess "Starting up $app_name container"
    fi
}

dockerScanForShouldRestart()
{
    for i in "${appstorestart[@]}"; do
        if [ "$i" -eq 3 ]; then
            unset appstorestart[$i]
            appstorestart=("${appstorestart[@]}") # Re-index the array
            i=$((i-1)) # Decrement the loop counter
        fi
        installApp "$i"
    done
}

dockerPruneNetworks()
{
    local result=$(runCommandForDocker "docker network prune -f")
    checkSuccess "Pruning any unused Docker networks"
}

dockerCheckContainerHealth() 
{
    local container_name="$1"
    local health_status=$(runCommandForDocker "docker inspect --format='{{json .State.Health.Status}}' $container_name")

    if [ "$health_status" == "\"healthy\"" ]; then
        return 0  # Container is healthy
    else
        return 1  # Container is not healthy
    fi
}

dockerCheckContainerHealthLoop() 
{
    local container_name="$1"
    local timeout="$2"
    local wait_time="$3"

    isNotice "This container health check will timeout after $timeout seconds"

    local counter=0
    while true; do
        if dockerCheckContainerHealth "$container_name"; then
            isSuccessful "Container is healthy!"
            break
        fi

        if [ "$counter" -ge "$timeout" ]; then
            isNotice "Container health check timed out after $timeout seconds. Exiting..."
            break
        fi

        isNotice "Waiting $wait_time seconds for container to turn healthy..."
        sleep "$wait_time"
        counter=$((counter + wait_time))
    done
}

isDockerRunningForUser() 
{
    local type="$1"

    # Check if Docker is running for the specified user
    if [[ $type == "rootless" ]]; then
        local docker_command='docker ps 2>&1'
        local result=$(runCommandForDockerInstallUser "$docker_command")
    elif [[ $type == "root" ]]; then
        local docker_command='sudo docker ps 2>&1'
        local result=$(eval "$docker_command")
    else
        echo "Invalid user type specified."
        return 1
    fi

    # Check the result
    if [[ $result =~ "Cannot connect to the Docker daemon" ]]; then
        #echo "Docker is not running for the specified user."
        return 1  # Docker is not running
    else
        #echo "Docker is running for the specified user."
        return 0  # Docker is running
    fi
}

dockerSwitchBetweenRootAndRootless()
{
    local run_switcher="false"

    if [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
        if isDockerRunningForUser "rootless"; then
            run_switcher="true"
            switch_type="root"
        fi
    fi

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        if isDockerRunningForUser "root"; then
            run_switcher="true"
            switch_type="rootless"
        fi
    fi

    scanContainersForDockerSocket() 
    {
        local directory="$1"
        local type="$2"
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")

        for file in "$directory"/*; do
            if [ -f "$file" ]; then
                if [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
                    if grep -q "/var/run/docker.sock" "$file"; then
                        result=$(sudo sed -i -e "s|/var/run/docker.sock|/run/user/${docker_install_user_id}/docker.sock|g" "$file")
                        checkSuccess "Updated file: $file"
                    fi
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    if grep -q "/run/user/${docker_install_user_id}/docker.sock" "$file"; then
                        result=$(sudo sed -i -e "s|/run/user/${docker_install_user_id}/docker.sock|/var/run/docker.sock|g" "$file")
                        checkSuccess "Updated file: $file"
                    fi
                fi
            fi
        done
    }

    if [[ $run_switcher == "true" ]]; then
        echo ""
        echo "##########################################"
        echo "###   Docker Root/Rootless Switcher    ###"
        echo "##########################################"
        echo ""

        if [[ $switch_type == "root" ]]; then
            isNotice "Docker Rootless is currently running..."
            while true; do
                isQuestion "Would you like to switch to Rooted Docker? (y/n): "
                echo ""
                read -p "" switch_rooted_choice
                if [[ -n "$switch_rooted_choice" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
            if [[ "$switch_rooted_choice" == [yY] ]]; then
                isNotice "Switching to the Rooted Docker now..."
                stopDocker rootless;
                startDocker root;
                # Scannning the containers folder
                local subdirectories=($(find "$containers_dir" -maxdepth 1 -type d))
                for dir in "${subdirectories[@]}"; do
                    scanContainersForDockerSocket "$dir" "root"
                    restartApp $dir;
                done
            fi
        fi

        if [[ $switch_type == "rootless" ]]; then
            isNotice "Docker Rooted is currently running..."
            while true; do
                isQuestion "Would you like to switch to Rootless Docker? (y/n): "
                echo ""
                read -p "" switch_rootless_choice
                if [[ -n "$switch_rootless_choice" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
            if [[ "$switch_rootless_choice" == [yY] ]]; then
                isNotice "Switching to the Rootless Docker now..."
                stopDocker root;
                startDocker rootless;
                # Scannning the containers folder
                local subdirectories=($(find "$containers_dir" -maxdepth 1 -type d))
                for dir in "${subdirectories[@]}"; do
                    scanContainersForDockerSocket "$dir" "rootless"
                    restartApp $dir;
                done
            fi
        fi
    fi
}