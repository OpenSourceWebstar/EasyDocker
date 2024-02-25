#!/bin/bash

dockerConfigSetupToContainer()
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
        createFolders "$silent_flag" "$CFG_DOCKER_INSTALL_USER" "$target_path"
    fi

    if [ ! -f "$source_file" ]; then
        isError "The config file '$source_file' does not exist."
        return 1
    fi

    if [ ! -f "$target_path/$config_file" ]; then
        if [ "$silent_flag" == "loud" ]; then
            isNotice "Copying config file to '$target_path/$config_file'..."
        fi
        copyFile "$silent_flag" "$source_file" "$target_path/$config_file" $sudo_user_name | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
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
                            copyFile "loud" "$source_file" "$target_path/$config_file" $CFG_DOCKER_INSTALL_USER | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
                            source $target_path/$config_file
                            dockerConfigSetupToContainer "loud" $app_name;
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
            copyFile "loud" "$source_file" "$target_path/$config_file" $CFG_DOCKER_INSTALL_USER | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
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
    sourceScanFiles "app_configs";
}

dockerConfigSetupFileWithData()
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
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|- /run/user/${docker_install_user_id}/docker.sock|- /var/run/docker.sock|g" \
        "$full_file_path")
        checkSuccess "Updating docker socket for $app_name"
    fi

    if [[ $file_name == *"docker-compose"* ]]; then
        if [[ "$public" == "true" ]]; then    
            traefikSetupLabels $app_name $full_file_path;
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