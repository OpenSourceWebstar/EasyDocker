#!/bin/bash

gitFolderResetAndBackup()
{
    update_done=false
    # Folder setup
    # Check if the directory specified in $script_dir exists
    if [ ! -d "$backup_install_dir/$backupFolder" ]; then
        result=$(mkdirFolders "$backup_install_dir/$backupFolder")
        checkSuccess "Create the backup folder"
    fi
    result=$(cd $backup_install_dir)
    checkSuccess "Going into the backup install folder"

    # Copy folders
    result=$(copyFolder "$configs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the configs to the backup folder"
    result=$(copyFolder "$logs_dir" "$backup_install_dir/$backupFolder")
    checkSuccess "Copy the logs to the backup folder"

    # Reset git
    result=$(sudo -u $easydockeruser rm -rf $script_dir)
    checkSuccess "Deleting all Git files"
    result=$(mkdirFolders "$script_dir")
    checkSuccess "Create the directory if it doesn't exist"	
    cd "$script_dir"
    checkSuccess "Going into the install folder"
	result=$(sudo -u $easydockeruser git clone "$repo_url" "$script_dir" > /dev/null 2>&1)
    checkSuccess "Clone the Git repository"

    # Copy files back into the install folder
    result=$(copyFolders "$backup_install_dir/$backupFolder/" "$script_dir")
    checkSuccess "Copy the backed up folders back into the installation directory"

    # Zip up folder for safe keeping and remove folder
    result=$(sudo -u $easydockeruser zip -r "$backup_install_dir/$backupFolder.zip" "$backup_install_dir/$backupFolder")
    checkSuccess "Zipping up the the backup folder for safe keeping"
    result=$(sudo rm -rf "$backup_install_dir/$backupFolder")
    checkSuccess "Removing the backup folder"

    # Fixing the issue where the git does not use the .gitignore
    result=$(cd $script_dir)
    checkSuccess "Going into the install folder"
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_apps_system > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_apps_privacy > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_apps_user > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_backup > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_restore > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_general > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$config_file_requirements > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $configs_dir/$ip_file > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $logs_dir/$docker_log_file > /dev/null 2>&1
	sudo -u $easydockeruser git rm --cached $logs_dir/$backup_log_file > /dev/null 2>&1
    isSuccessful "Removing configs and logs from git for git changes"
    result=$(sudo -u $easydockeruser git commit -m "Stop tracking ignored files")
    checkSuccess "Removing tracking ignored files"

	isSuccessful "Custom changes have been discarded successfully"
	update_done=true
}

reloadScripts()
{
    # Reloading all scripts after clone
    for file in $script_dir*.sh; do
        [ -f "$file" ] && . "$file"
    done
}

function userExists() {
    if id "$1" &>/dev/null; then
        return 0 # User exists
    else
        return 1 # User does not exist
    fi
}

function checkSuccess() 
{
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS:${NC} $1"
        if [ -f "$logs_dir/$docker_log_file" ]; then
            echo "SUCCESS: $1" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" >/dev/null
        fi
    else
        echo -e "${RED}ERROR:${NC} $1"
        # Ask to continue
        while true; do
            isQuestion "An error has occurred. Do you want to continue, exit or go to back to the Menu? (c/x/m) "
            read -rp "" error_occurred
            if [[ -n "$error_occurred" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done

        if [[ "$error_occurred" == [cC] ]]; then
            isNotice "Continuing after error has occured."
        fi

        if [[ "$error_occurred" == [xX] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            exit 1  # Exit the script with a non-zero status to stop the current action
        fi

        if [[ "$error_occurred" == [mM] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file"
            resetToMenu
        fi
    fi
}

function isSuccessful() 
{
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

function isError() 
{
    echo -e "${RED}ERROR:${NC} $1"
}

function isFatalError() 
{
    echo -e "${RED}ERROR:${NC} $1"
}

function isFatalErrorExit() 
{
    echo -e "${RED}ERROR:${NC} $1"
    echo ""
    exit 1
}

function isNotice() 
{
    echo -e "${YELLOW}NOTICE:${NC} $1"
}

function isQuestion() 
{
    echo -e -n "${BLUE}QUESTION:${NC} $1 "
}

function isOptionMenu() 
{
    echo -e -n "${PINK}OPTION:${NC} $1"
}

function isOption() 
{
    echo -e "${PINK}OPTION:${NC} $1"
}

detectOS() 
{
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$NAME" in
            "Debian GNU/Linux")
                detected_os="Debian 10 / 11 / 12"
                OS=1 ;;
            "Ubuntu")
                case "$VERSION_ID" in
                    "18.04")
                        detected_os="Ubuntu 18.04"
                        OS=2 ;;
                    "20.04" | "21.04" | "22.04")
                        detected_os="Ubuntu 20.04 / 21.04 / 22.04"
                        OS=3 ;;
                esac
                ;;
            "Arch Linux")
                detected_os="Arch Linux"
                OS=4 ;;
            *)  # Default selection (End this Installer)
                echo "Unable to detect OS."
                exit 1 ;;
        esac

        echo ""
        checkSuccess "Detected OS: $detected_os"

        if [ "$OS" -gt 1 ]; then
            isError "This OS ($detected_os) is untested and may not be fully supported."
            while true; do
                isQuestion "Do you wish to continue anyway? (y/n): "
                read -rp "" oswarningaccept
                if [[ -n "$oswarningaccept" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        fi

        installDockerUser;
        scanConfigsForRandomPassword;
        fixFolderPermissions;
        checkRequirements;
    else
        checkSuccess "Unable to detect OS."
        exit 1
    fi
}

runCommandForDockerInstallUser() 
{
    local remote_command="$1"

    # Run the SSH command using the existing SSH variables
    result=$(sshpass -p "$CFG_DOCKER_INSTALL_PASS" ssh -o StrictHostKeyChecking=no "$CFG_DOCKER_INSTALL_USER@localhost" "$remote_command")
}

checkConfigFilesExist() 
{
	if [[ $CFG_REQUIREMENT_CONFIG == "true" ]]; then
        local files_to_check=("$config_file_apps_system" "$config_file_apps_privacy" "$config_file_apps_user" "$config_file_backup" "$config_file_general" "$config_file_restore" "$config_file_requirements")
        local file_found_count=0

        for file in "${files_to_check[@]}"; do
            if [ -f "$configs_dir/$file" ]; then
                ((file_found_count++))
            else
                isFatalError "Config File $file does not exist in $configs_dir."
                isFatalErrorExit "Please make sure all configs are present"
            fi
        done

        if [ "$file_found_count" -eq "${#files_to_check[@]}" ]; then
            isSuccessful "All config files are found in the configs folder."
        else
            isFatalError "Not all config files were found in $configs_dir."
        fi
    fi
}

checkConfigFilesEdited()
{
    # Flag to control the loop
    config_check_done=false

    while ! "$config_check_done"; do
        # Check if configs have not been changed
        if grep -q "Change-Me" "$configs_dir/$config_file_general"; then
            echo ""
            isNotice "Default config values have been found, have you edited the config files?"
            echo ""
            while true; do
                isQuestion "Would you like to continue with the default config values or edit them? (c/e): "
                read -rp "" configsnotchanged
                echo ""
                case $configsnotchanged in
                    [cC])
                        isNotice "Config files have been accepted with the default values, continuing... "
                        config_check_done=true  # Set the flag to exit the loop
                        break  # Exit the loop
                        ;;
                    [eE])
                        viewConfigs
                        # No need to set config_check_done here; it will continue to the next iteration of the loop
                        break  # Exit the loop
                        ;;
                    *)
                        isNotice "Please provide a valid input (c or e)."
                        ;;
                esac
            done
        else
            isSuccessful "Config file has been updated, continuing..."
            config_check_done=true  # Set the flag to exit the loop
        fi
    done
}

# Function to view log file with different options
viewLogs()
{
    if [ ! -f "$logs_dir/$docker_log_file" ]; then
        isError "Log file not found: $docker_log_file"
        return 1
    fi

    echo ""
    echo "#################################"
    echo "###     Log Viewer Options    ###"
    echo "#################################"
    echo ""
    isOption "1. Show last 20 lines"
    isOption "2. Show last 50 lines"
    isOption "3. Show last 100 lines"
    isOption "4. Show last 200 lines"
    isOption "5. Show full log"
    isOption "x. Exit"
    echo ""

    isQuestion "Enter your choice (1-5): "
    read -p "" log_choice

    case "$log_choice" in
        1)
            isNotice "Showing last 20 lines of $docker_log_file:"
            tail -n 20 "$logs_dir/$docker_log_file"
            ;;
        2)
            isNotice "Showing last 50 lines of $docker_log_file:"
            tail -n 50 "$logs_dir/$docker_log_file"
            ;;
        3)
            isNotice "Showing last 100 lines of $docker_log_file:"
            tail -n 100 "$logs_dir/$docker_log_file"
            ;;
        4)
            isNotice "Showing last 200 lines of $docker_log_file:"
            tail -n 200 "$logs_dir/$docker_log_file"
            ;;
        5)
            isNotice "Showing the full content of $docker_log_file:"
            nano "$logs_dir/$docker_log_file"
            ;;
        6)
            isNotice "Exiting"
            return
            ;;
        *)
            isNotice "Invalid choice. Please select a valid option (1-5)."
            ;;
    esac
}

viewConfigs() 
{
  local config_files=("$configs_dir"*)  # List all files in the /configs/ folder

  echo ""
  echo "#################################"
  echo "###    Manage Config Files    ###"
  echo "#################################"
  echo ""

  if [ ${#config_files[@]} -eq 0 ]; then
    isNotice "No files found in /configs/ folder."
    return
  fi

  declare -A config_timestamps  # Associative array to store config names and their modified timestamps

  PS3="Select a config to edit (Type the first letter of the config, or x to exit): "
  while true; do
    for ((i = 0; i < ${#config_files[@]}; i++)); do
      file_name=$(basename "${config_files[i]}")  # Get the basename of the file
      file_name_without_prefix=${file_name#config_}  # Remove the "config_" prefix from all files
      config_name=${file_name_without_prefix,,}  # Convert the name to lowercase
      
      if [[ "$file_name" == config_apps_* ]]; then
        config_name=${config_name#apps_}  # Remove the "apps_" prefix from files with that prefix
      fi

      first_letter=${config_name:0:1}  # Get the first letter

      # Check if the config name is in the associative array and retrieve the last modified timestamp
      if [ "${config_timestamps[$config_name]}" ]; then
        last_modified="${config_timestamps[$config_name]}"
      else
        last_modified=$(stat -c "%y" "${config_files[i]}")  # Get last modified time if not already in the array
        config_timestamps["$config_name"]=$last_modified  # Store the last modified timestamp in the array
      fi

      formatted_last_modified=$(date -d "$last_modified" +"%m/%d %H:%M")  # Format the timestamp

      if [[ "$file_name" == "config_apps_privacy" ]]; then
        isOption "$first_letter. apps_privacy (Last modified: $formatted_last_modified)"
      elif [[ "$file_name" == "config_apps_system" ]]; then
        isOption "$first_letter. apps_system (Last modified: $formatted_last_modified)"
      elif [[ "$file_name" == "config_apps_user" ]]; then
        isOption "$first_letter. apps_user (Last modified: $formatted_last_modified)"
      else
        isOption "$first_letter. ${config_name,,} (Last modified: $formatted_last_modified)"
      fi
    done

    isOption "x. Exit"
    echo ""
    isQuestion "Enter the first letter of the config (or x to exit): "
    read -p "" selected_letter

    if [[ "$selected_letter" == "x" ]]; then
      isNotice "Exiting."
      return
    elif [[ "$selected_letter" =~ [A-Za-z] ]]; then
      selected_file=""
      for ((i = 0; i < ${#config_files[@]}; i++)); do
        file_name=$(basename "${config_files[i]}")
        file_name_without_prefix=${file_name#config_}
        config_name=${file_name_without_prefix,,}
        
        if [[ "$file_name" == config_apps_* ]]; then
          config_name=${config_name#apps_}
        fi
        
        first_letter=${config_name:0:1}
        if [[ "$selected_letter" == "$first_letter" ]]; then
          selected_file="${config_files[i]}"
          break
        fi
      done

      if [ -z "$selected_file" ]; then
        isNotie "No config found with the selected letter. Please try again."
        read -p "Press Enter to continue."
      else
        nano "$selected_file"

        # Update the last modified timestamp of the edited file
        createTouch "$selected_file"

        # Store the updated last modified timestamp in the associative array
        config_name=$(basename "${selected_file}" | sed 's/config_//')
        config_timestamps["$config_name"]=$(stat -c "%y" "$selected_file")

        # Show a notification message indicating the config has been updated
        echo ""
        isNotice "Configuration file '$config_name' has been updated."
        echo ""
      fi
    else
      isNotice "Invalid input. Please enter a valid letter or 'x' to exit."
      echo ""
      read -p "Press Enter to continue."
    fi
  done
}

setupIPsAndHostnames() 
{
    found_match=false
    while read -r line; do
        local hostname=$(echo "$line" | awk '{print $1}')
        local ip=$(echo "$line" | awk '{print $2}')

        if [ "$hostname" = "$host_name" ]; then
            found_match=true
            # Public variables
            domain_prefix=$hostname
            domain_var_name="CFG_DOMAIN_${domain_number}"
            domain_full=$(sudo grep  "^$domain_var_name=" $configs_dir/config_general | cut -d '=' -f 2-)
            host_setup=${domain_prefix}.${domain_full}
            ssl_key=${domain_full}.key
            ssl_crt=${domain_full}.crt
            ip_setup=$ip

            if [[ "$public" == "true" ]]; then
                isSuccessful "Using $host_setup for public domain."
                checkSuccess "Match found: $hostname with IP $ip."  # Moved this line inside the conditional block
                echo ""
            fi
        fi
    done < "$configs_dir$ip_file"

    if ! "$found_match"; then  # Changed the condition to check if no match is found
        checkSuccess "No matching hostnames found for $host_name, please fill in the ips_hostname file"
        echo ""
    fi
}

setupComposeFileNoApp() 
{
    local target_path="$install_path$app_name"
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
    local target_path="$install_path$app_name"
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
            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose down")
            checkSuccess "Shutting down container for $app_name"

            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose up -q -d")
            checkSuccess "Starting up container for $app_name"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo -u $easydockeruser docker-compose down)
            checkSuccess "Shutting down container for $app_name"

            result=$(sudo -u $easydockeruser docker-compose up -q -d)
            checkSuccess "Starting up container for $app_name"
        fi
    else
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose down")
            checkSuccess "Shutting down container for $app_name"

            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose up -q -d")
            checkSuccess "Starting up container for $app_name"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo -u $easydockeruser docker-compose down)
            checkSuccess "Shutting down container for $app_name"

            result=$(sudo -u $easydockeruser docker-compose up -q -d)
            checkSuccess "Starting up container for $app_name"
        fi
    fi
}

dockerUpDownAdditionalYML()
{
    if [[ "$OS" == [123] ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"

            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q up -d")
            checkSuccess "Starting up container for $app_name (Using additional yml file)"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down)
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"

            result=$(sudo -u $easydockeruser docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q up -d)
            checkSuccess "Starting up container for $app_name (Using additional yml file)"
        fi
    else
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml down")
            checkSuccess "Shutting down container for $app_name (Using additional yml file)"

            result=$(runCommandForDockerInstallUser "cd $install_path$app_name && docker-compose -f docker-compose.yml -f docker-compose.$app_name.yml -q -q up -d")
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
    local compose_file="$install_path$app_name/docker-compose.yml"

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
            checkSuccess "Disable Traefik options for private setup)"
        fi
    fi

    isSuccessful "Updated the $app_name docker-compose.yml"
}

editComposeFileApp() 
{
    local compose_file="$install_path$app_name/docker-compose.$app_name.yml"

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
            checkSuccess "Disable Traefik options for private setup)"
        fi
    fi

    isSuccessful "Updated the docker-compose.$app_name.yml"
}

editEnvFileDefault() 
{
    local env_file="$install_path$app_name/.env"

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

passwordValidation()
{
    # Password Setup for DB with complexity checking
    # Initialize valid password flag
    valid_password=false
    # Loop until a valid password is entered
    while [ $valid_password = false ]
    do
        # Prompt the user for a password
        echo -n "Enter your password: "
        # Disable echoing of the password input, so that it is not displayed on the screen
        stty -echo
        # Read in the password input
        read password
        # Re-enable echoing of the input
        stty echo
        echo
        # Check the length of the password
        if [ ${#password} -lt 8 ]; then
            isError "Password is too short. Please enter a password with at least 8 characters."
            continue
        fi
        # Check the complexity of the password
        if ! [[ "$password" =~ [[:lower:]] ]] || ! [[ "$password" =~ [[:upper:]] ]] || ! [[ "$password" =~ [[:digit:]] ]]; then
            isError "Password is not complex enough. Please include at least one uppercase letter, one lowercase letter, and one numeric digit."
            continue
        fi
        # If we make it here, the password is valid
            valid_password=true
    done
}

emailValidation()
{
    # Initialize email variable to empty string
    email=""

    # Loop until a valid email is entered
    while [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do

        # Prompt user to submit email
        isQuestion "Please enter your email address: "
        read -p "" email

        # Check email format using regex
        if [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            isError "Invalid email format. Please try again."
        fi

    done
}

removeEmptyLineAtFileEnd() 
{
  local file_path="$1"
  local last_line=$(tail -n 1 "$file_path")
  
  if [ -z "$last_line" ]; then
    result=$(sudo sed -i '$d' "$file_path")
    checkSuccess "Removed the empty line at the end of $file_path"
  fi
}

scanConfigsForRandomPassword() 
{
    if [[ "$CFG_REQUIREMENT_PASSWORDS" == "true" ]]; then
        echo ""
        echo "##########################################"
        echo "###    Randomizing Config Passwords    ###"
        echo "##########################################"
        echo ""
        # Iterate through files in the folder
        for scanned_config_file in "$configs_dir"/*; do
            if [ -f "$scanned_config_file" ]; then
                # Check if the file contains the placeholder string "RANDOMIZEDPASSWORD"
                while sudo grep  -q "RANDOMIZEDPASSWORD" "$scanned_config_file"; do
                    # Generate a unique random password
                    local random_password=$(openssl rand -base64 12 | tr -d '+/=')

                    # Capture the content before "RANDOMIZEDPASSWORD"
                    local config_content=$(sudo sed -n "s/RANDOMIZEDPASSWORD.*$/${random_password}/p" "$scanned_config_file")

                    # Update the first occurrence of "RANDOMIZEDPASSWORD" with the new password
                    sudo sed -i "0,/\(RANDOMIZEDPASSWORD\)/s//${random_password}/" "$scanned_config_file"

                    # Display the update message with the captured content and file name
                    #isSuccessful "Updated $config_content in $(basename "$scanned_config_file") with a new password: $random_password"
                done
            fi
        done
        isSuccessful "Random password generation and update completed successfully."
    fi
}

setupEnvFile()
{
    result=$(copyFile $install_path$app_name/env.example $install_path$app_name/.env)
    checkSuccess "Setting up .env file to path"
}

dockerStopAllApps()
{
    isNotice "Please wait for docker containers to stop"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(runCommandForDockerInstallUser "docker stop $(docker ps -a -q)")
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
        result=$(runCommandForDockerInstallUser "docker restart $(docker ps -a -q)")
        checkSuccess "Starting up all docker containers"
    elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo -u $easydockeruser docker restart $(docker ps -a -q))
        checkSuccess "Starting up all docker containers"
    fi
}

dockerAppDown()
{
    isNotice "Please wait for $app_name container to stop"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(runCommandForDockerInstallUser "docker ps -a --format '{{.Names}}' | grep "$app_name" | xargs docker stop")
        checkSuccess "Shutting down $app_name container"
    elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo -u $easydockeruser docker ps -a --format '{{.Names}}' | grep "$app_name" | xargs docker stop)
        checkSuccess "Shutting down $app_name container"
    fi
}

dockerAppUp()
{
    isNotice "Please wait for $app_name container to start"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(runCommandForDockerInstallUser "docker ps -a --format '{{.Names}}' | grep "$app_name" | xargs docker restart")
        checkSuccess "Starting up $app_name container"
    elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo -u $easydockeruser docker ps -a --format '{{.Names}}' | grep "$app_name" | xargs docker restart)
        checkSuccess "Starting up $app_name container"
    fi
}

showInstallInstructions()
{
    echo ""
    echo "#####################################"
    echo "###       Usage Instructions      ###"
    echo "#####################################"
    echo ""
    isNotice "Please select 'i' for each item you would like to install."
    isNotice "Please select 'u' for each item you would like to uninstall."
    isNotice "Please select 's' for each item you would like to shutdown."
    isNotice "Please select 'r' for each item you would like to restart."
}

completeMessage()
{
    echo ""
    isSuccessful "You seem to have reached the end of the script! Restarting.... <3"
    echo ""
    sleep 1
}

resetToMenu()
{
    # Apps
    fail2ban=n
    traefik=n
    wireguard=n
    pihole=n
    portainer=n
    watchtower=n
    dashy=n
    searxng=n
    speedtest=n
    ipinfo=n
    trilium=n
    vaultwarden=n
    jitsimeet=n
    owncloud=n
    killbill=n
    mattermost=n
    kimai=n
    mailcow=n
    tiledesk=n
    gitlab=n
    actual=n
    akaunting=n
    cozy=n
    duplicati=n
    caddy=n

    # Backup
    backupsingle=n
    backupfull=n

    # Restore
    restoresingle=n
    restorefull=n

    # Mirate
    migratecheckforfiles=n
    migratemovefrommigrate=n
    migrategeneratetxt=n
    migratescanforupdates=n
    migratescanforconfigstomigrate=n
    migratescanformigratetoconfigs=n

    # Database
    toollistalltables=n
    toollistallapps=n
    toollistinstalledapps=n
    toolupdatedb=n
    toolemptytable=n
    tooldeletedb=n

    # Tools
    toolsresetgit=n
    toolstartpreinstallation=n
    toolsstartcrontabsetup=n
    toolrestartcontainers=n
    toolstopcontainers=n
    toolsremovedockermanageruser=n
    toolsinstalldockermanageruser=n
    toolinstallremotesshlist=n
    toolinstallcrontab=n
    toolinstallcrontabssh=n

    mainMenu
    return 1
}