#!/bin/bash

checkConfigFilesMissingVariables()
{
    local showheader="$1"

    if [[ $showheader == "true" ]]; then
        echo ""
        echo "#################################"
        echo "###   Scanning Config Files   ###"
        echo "#################################"
        echo ""
    fi
    checkEasyDockerConfigFilesMissingVariables;
    checkApplicationsConfigFilesMissingVariables;

}

checkEasyDockerConfigFilesMissingVariables()
{
    #isNotice "Scanning EasyDocker config files...please wait"

    # Loop through local config files in $configs_dir
    for local_config_file in "$configs_dir"/*; do
        if [ -f "$local_config_file" ]; then
            local local_config_filename=$(basename "$local_config_file")

            # Extract config variables from the local file
            local local_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$local_config_file" | sed 's/=$//'))

            #echo "Debug: Found local config file: $local_config_filename"
            #echo "Debug: Local config variables: ${local_variables[@]}"

            # Find the corresponding .config file in $install_configs_dir
            local remote_config_file="$install_configs_dir$local_config_filename"

            if [ -f "$remote_config_file" ]; then
                #echo "Debug: Found remote config file: $remote_config_file"

                # Extract config variables from the remote file
                local remote_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$remote_config_file" | sed 's/=$//'))

                #echo "Debug: Remote config variables: ${remote_variables[@]}"

                # Filter out empty variable names from the remote variables
                local remote_variables=("${remote_variables[@]//[[:space:]]/}")  # Remove whitespace
                local remote_variables=($(echo "${remote_variables[@]}" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' '))

                #echo "Debug: Remote variables after filtering: ${remote_variables[@]}"

                # Compare local and remote variables
                for remote_var in "${remote_variables[@]}"; do
                    if ! [[ " ${local_variables[@]} " =~ " $remote_var " ]]; then
                        var_line=$(grep "${remote_var}=" "$remote_config_file")

                        echo ""
                        echo "####################################################"
                        echo "###   Missing EasyDocker Config Variable Found   ###"
                        echo "####################################################"
                        echo ""
                        isNotice "Variable '$remote_var' is missing in the local config file '$local_config_filename'."
                        echo ""
                        isOption "1. Add the '$var_line' to the '$local_config_filename'"
                        isOption "2. Add the '$remote_var' with my own value"
                        isOption "x. Skip"
                        echo ""

                        isQuestion "Enter your choice (1 or 2) or 'x' to skip : "
                        read -rp "" choice

                        case "$choice" in
                            1)
                                echo ""
                                # Check if the file ends with an empty line
                                if fileHasEmptyLine "$local_config_file"; then
                                    echo "$var_line" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                else
                                    echo "" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                    echo "$var_line" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                fi

                                checkSuccess "Adding the $var_line to '$local_config_filename':"
                                source "$local_config_file"
                            ;;
                            2)
                                echo ""
                                isQuestion "Enter your value for $remote_var: "
                                read -p " " custom_value
                                echo ""

                                if fileHasEmptyLine "$local_config_file"; then
                                    echo "${remote_var}=$custom_value" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                else
                                    echo "" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                    echo "${remote_var}=$custom_value" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                fi

                                checkSuccess "Adding the ${remote_var}=$custom_value to '$local_config_filename':"
                                source "$local_config_file"
                            ;;
                            [xX])
                                # User chose to skip
                            ;;
                            *)
                                echo "Invalid choice. Skipping."
                            ;;
                        esac
                    fi
                done
            #else
                #echo "Debug: Remote config file not found: $remote_config_file"
            fi
        fi
    done

    isSuccessful "EasyDocker Config variable check completed."  # Indicate completion
}

checkApplicationsConfigFilesMissingVariables() 
{
    #isNotice "Scanning Application config files...please wait"
    local container_configs=($(sudo find "$containers_dir" -maxdepth 2 -type f -name '*.config'))  # Find .config files in immediate subdirectories of $containers_dir

    for container_config_file in "${container_configs[@]}"; do
        local container_config_filename=$(basename "$container_config_file")
        local config_app_name="${container_config_filename%.config}"

        # Extract config variables from the local file
        local local_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$container_config_file" | sed 's/=$//'))

        #echo "Debug: Found local config file: $container_config_filename"
        #echo "Debug: Local config variables: ${local_variables[@]}"

        # Find the corresponding .config file in $install_containers_dir
        local remote_config_file="$install_containers_dir$config_app_name/$config_app_name.config"

        if [ -f "$remote_config_file" ]; then
            #echo "Debug: Found remote config file: $remote_config_file"

            # Extract config variables from the remote file
            local remote_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$remote_config_file" | sed 's/=$//'))

            #echo "Debug: Remote config variables: ${remote_variables[@]}"

            # Filter out empty variable names from the remote variables
            local remote_variables=("${remote_variables[@]//[[:space:]]/}")  # Remove whitespace
            local remote_variables=($(echo "${remote_variables[@]}" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' '))

            #echo "Debug: Remote variables after filtering: ${remote_variables[@]}"

            # Compare local and remote variables
            for remote_var in "${remote_variables[@]}"; do
                if ! [[ " ${local_variables[@]} " =~ " $remote_var " ]]; then
                    local var_line=$(grep "${remote_var}=" "$remote_config_file")

                    echo ""
                    echo "####################################################"
                    echo "###   Missing Application Config Variable Found  ###"
                    echo "####################################################"
                    echo ""
                    isNotice "Variable '$remote_var' is missing in the local config file '$container_config_filename'."
                    echo ""
                    isOption "1. Add the '$var_line' to the '$container_config_filename'"
                    isOption "2. Add the '$remote_var' with my own value"
                    isOption "x. Skip"
                    echo ""

                    isQuestion "Enter your choice (1 or 2) or 'x' to skip : "
                    read -rp "" choice

                    case "$choice" in
                        1)
                            echo ""

                            if fileHasEmptyLine "$container_config_file"; then
                                echo "$var_line" | sudo tee -a "$container_config_file" > /dev/null 2>&1
                            else
                                echo "" | sudo tee -a "$container_config_file" > /dev/null 2>&1
                                echo "$var_line" | sudo tee -a "$container_config_file" > /dev/null 2>&1
                            fi

                            checkSuccess "Adding the $var_line to '$container_config_filename':"
                            source "$container_config_file"

                            if [[ $var_line == *"WHITELIST="* ]]; then
                                local app_dir=$install_containers_dir$config_app_name
                                # Check if app is installed
                                if [ -d "$app_dir" ]; then
                                    echo ""
                                    isNotice "Whitelist has been added to the $config_app_name."
                                    echo ""
                                    while true; do
                                        isQuestion "Would you like to update the ${config_app_name}'s whitelist settings? (y/n): "
                                        read -rp "" whitelistaccept
                                        echo ""
                                        case $whitelistaccept in
                                            [yY])
                                                isNotice "Updating ${config_app_name}'s whitelist settings..."
                                                whitelistAndStartApp $config_app_name;
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
                                local app_dir=$install_containers_dir$config_app_name
                                # Check if app is installed
                                if [ -d "$app_dir" ]; then
                                    echo ""
                                    isNotice "A new config value has been added to $config_app_name."
                                    echo ""
                                    while true; do
                                        isQuestion "Would you like to reinstall $config_app_name? (y/n): "
                                        read -rp "" reinstallafterconfig
                                        echo ""
                                        case $reinstallafterconfig in
                                            [yY])
                                                isNotice "Reinstalling $config_app_name now..."
                                                local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${config_app_name:0:1})${config_app_name:1}"
                                                local installFuncName="install${app_name_ucfirst}"
                                                ${installFuncName} install
                                                break  # Exit the loop
                                                ;;
                                            [nN])
                                                break  # Exit the loop
                                                ;;
                                            *)
                                                isNotice "Please provide a valid input (y or n)."
                                                ;;
                                        esac
                                    done
                                fi
                            fi
                            ;;
                        2)
                            echo ""
                            isQuestion "Enter your value for $remote_var: "
                            read -p " " custom_value
                            echo ""

                            if fileHasEmptyLine "$container_config_file"; then
                                echo "${remote_var}=$custom_value" | sudo tee -a "$container_config_file" > /dev/null 2>&1
                            else
                                echo "" | sudo tee -a "$container_config_file" > /dev/null 2>&1
                                echo "${remote_var}=$custom_value" | sudo tee -a "$container_config_file" > /dev/null 2>&1
                            fi

                            checkSuccess "Adding the ${remote_var}=$custom_value to '$container_config_filename':"
                            source "$container_config_file"

                            if [[ $remote_var == *"WHITELIST="* ]]; then
                                local app_dir=$install_containers_dir$config_app_name
                                # Check if app is installed
                                if [ -d "$app_dir" ]; then
                                    echo ""
                                    isNotice "Whitelist has been added to the $config_app_name."
                                    echo ""
                                    while true; do
                                        isQuestion "Would you like to update the ${config_app_name}'s whitelist settings? (y/n): "
                                        read -rp "" whitelistaccept
                                        echo ""
                                        case $whitelistaccept in
                                            [yY])
                                                isNotice "Updating ${config_app_name}'s whitelist settings..."
                                                whitelistAndStartApp $config_app_name;
                                                break  # Exit the loop
                                                ;;
                                            [nN])
                                                break  # Exit the loop
                                                ;;
                                            *)
                                                isNotice "Please provide a valid input (y or n)."
                                                ;;
                                        esac
                                    done
                                fi
                            else
                                local app_dir=$install_containers_dir$config_app_name
                                # Check if app is installed
                                if [ -d "$app_dir" ]; then
                                    echo ""
                                    isNotice "A new config value has been added to $config_app_name."
                                    echo ""
                                    while true; do
                                        isQuestion "Would you like to reinstall $config_app_name? (y/n): "
                                        read -rp "" reinstallafterconfig
                                        echo ""
                                        case $reinstallafterconfig in
                                            [yY])
                                                isNotice "Reinstalling $config_app_name now..."
                                                local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${config_app_name:0:1})${config_app_name:1}"
                                                local installFuncName="install${app_name_ucfirst}"
                                                ${installFuncName} install
                                                break  # Exit the loop
                                                ;;
                                            [nN])
                                                break  # Exit the loop
                                                ;;
                                            *)
                                                isNotice "Please provide a valid input (y or n)."
                                                ;;
                                        esac
                                    done
                                fi
                            fi
                            ;;
                        [xX])
                            # User chose to skip
                            ;;
                        *)
                            echo "Invalid choice. Skipping."
                            ;;
                    esac
                fi
            done
        fi
    done

    isSuccessful "Application Config variable check completed."  # Indicate completion
}

checkConfigFilesEdited()
{
    # Flag to control the loop
    local config_check_done=false
    
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
            local config_check_done=true  # Set the flag to exit the loop
        fi
    done
}

editAppConfig() 
{
    local app_name="$1"
    local config_file
    local app_dir

    if [[ "$app_name" == "" ]]; then
        return
    fi

    # Use find to search for the app_name folder within $containers_dir
    local app_dir=$containers_dir$app_name

    if [ -n "$app_dir" ]; then
        local config_file="$app_dir/$app_name.config"

        if [ -f "$config_file" ]; then
            # Calculate the checksum of the original file
            local original_checksum=$(md5sum "$config_file")

            # Open the file with nano for editing
            sudo nano "$config_file"

            # Calculate the checksum of the edited file
            local edited_checksum=$(md5sum "$config_file")

            # Compare the checksums to check if changes were made
            if [[ "$original_checksum" != "$edited_checksum" ]]; then
                source $config_file
                #cat $config_file
                # Ask the user if they want to reinstall the application
                echo ""
                echo "############################################"
                echo "######    App Config Changes Found    ######"
                echo "############################################"
                while true; do
                    echo ""
                    isNotice "Changes have been made to the $app_name configuration."
                    echo ""
                    isQuestion "Would you like to reinstall $app_name? (y/n): "
                    read -p "" reinstall_choice
                    if [[ -n "$reinstall_choice" ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
                if [[ "$reinstall_choice" =~ [yY] ]]; then
                    # Run to see if edits have removed any variables
                    checkConfigFilesMissingVariables;
                    # Convert the first letter of app_name to uppercase
                    local app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
                    local installFuncName="install${app_name_ucfirst}"
                    ${installFuncName} install 
                fi
            else
                isNotice "No changes were made to the $app_name configuration."
            fi
        else
            echo "Config file not found for $app_name."
        fi
    else
        echo "App folder not found for $app_name."
    fi
}

viewEasyDockerConfigs()
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
            local file_name=$(basename "${config_files[i]}")  # Get the basename of the file
            local file_name_without_prefix=${file_name#config_}  # Remove the "config_" prefix from all files
            local config_name=${file_name_without_prefix,,}  # Convert the name to lowercase
            
            if [[ "$file_name" == config_apps_* ]]; then
                local config_name=${config_name#apps_}  # Remove the "apps_" prefix from files with that prefix
            fi
            
            local first_letter=${config_name:0:1}  # Get the first letter
            
            # Check if the config name is in the associative array and retrieve the last modified timestamp
            if [ "${config_timestamps[$config_name]}" ]; then
                local last_modified="${config_timestamps[$config_name]}"
            else
                local last_modified=$(stat -c "%y" "${config_files[i]}")  # Get last modified time if not already in the array
                local config_timestamps["$config_name"]=$last_modified  # Store the last modified timestamp in the array
            fi
            
            local formatted_last_modified=$(date -d "$last_modified" +"%m/%d %H:%M")  # Format the timestamp
            
            isOption "$first_letter. ${config_name,,} (Last modified: $formatted_last_modified)"
        done
        
        isOption "x. Exit"
        echo ""
        isQuestion "Enter the first letter of the config (or x to exit): "
        read -p "" selected_letter
        
        if [[ "$selected_letter" == "x" ]]; then
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for EasyDocker."
                echo ""
                loadFiles "easydocker_configs";
            else
                isNotice "Exiting..."
                echo ""
                checkConfigFilesMissingVariables true;
                databaseCycleThroughListAppsCrontab true;
                return
            fi
            elif [[ "$selected_letter" =~ [A-Za-z] ]]; then
            local selected_file=""
            for ((i = 0; i < ${#config_files[@]}; i++)); do
               local  file_name=$(basename "${config_files[i]}")
                local file_name_without_prefix=${file_name#config_}
                local config_name=${file_name_without_prefix,,}
                
                if [[ "$file_name" == config_apps_* ]]; then
                    local config_name=${config_name#apps_}
                fi
                
                local first_letter=${config_name:0:1}
                if [[ "$selected_letter" == "$first_letter" ]]; then
                    local selected_file="${config_files[i]}"
                    break
                fi
            done
            
            if [ -z "$selected_file" ]; then
                isNotie "No config found with the selected letter. Please try again."
                read -p "Press Enter to continue."
            else
                sudo nano "$selected_file"
                
                # Update the last modified timestamp of the edited file
                createTouch "$selected_file"
                
                # Store the updated last modified timestamp in the associative array
                local config_name=$(basename "${selected_file}" | sed 's/config_//')
                local config_timestamps["$config_name"]=$(stat -c "%y" "$selected_file")
                
                # Show a notification message indicating the config has been updated
                echo ""
                isNotice "Configuration file '$config_name' has been updated."
                echo ""
                #config_edited=true
            fi
        else
            isNotice "Invalid input. Please enter a valid letter or 'x' to exit."
            echo ""
            read -p "Press Enter to continue."
        fi
    done
}

# Function to list Docker Compose files in a directory
listDockerComposeFiles() 
{
  local dir="$1"
  local docker_compose_files=()

  for file in "$dir"/*; do
    if [[ -f "$file" && "$file" == *docker-compose* ]]; then
      docker_compose_files+=("$file")
    fi
  done

  echo "${docker_compose_files[@]}"
}

# Function to view and edit Docker Compose files in a selected app's folder
viewComposeFiles() 
{
  local app_names=()
  local app_dir

  echo ""
  echo "#################################"
  echo "### Docker Compose YML Editor ###"
  echo "#################################"
  echo ""
  isNotice "*WARNING* Only use this if you know what you are doing!"
  echo ""

  # Find all subdirectories under $containers_dir
  for app_dir in "$containers_dir"/*/; do
    if [[ -d "$app_dir" ]]; then
      # Extract the app name (folder name)
      local app_name=$(basename "$app_dir")
      local app_names+=("$app_name")
    fi
  done

  # Check if any apps were found
  if [ ${#app_names[@]} -eq 0 ]; then
    isNotice "No apps found in $containers_dir."
    return
  fi

  # List numbered options for app names
  isNotice "Select an app to view and edit Docker Compose files:"
  echo ""
  for i in "${!app_names[@]}"; do
    isOption "$((i + 1)). ${app_names[i]}"
  done

  # Read user input for app selection
  echo ""
  isQuestion "Enter the number of the app (or 'x' to exit): "
  read -p "" selected_option

  case "$selected_option" in
    [1-9]*)
      # Check if the selected option is a valid number
      if ((selected_option >= 1 && selected_option <= ${#app_names[@]})); then
        local selected_app="${app_names[selected_option - 1]}"
        local selected_app_dir="$containers_dir/$selected_app"

        # List Docker Compose files in the selected app's folder
        echo ""
        isNotice "Docker Compose files in '$selected_app':"
        local selected_compose_files=($(listDockerComposeFiles "$selected_app_dir"))

        # Check if any Docker Compose files were found
        if [ ${#selected_compose_files[@]} -eq 0 ]; then
          isNotice "No Docker Compose files found in '$selected_app'."
        else
          while true; do
            # List numbered options for Docker Compose files
            isNotice "Select Docker Compose files to edit (space-separated numbers, or 'x' to exit):"
            echo ""
            for i in "${!selected_compose_files[@]}"; do
              local compose_file_name=$(basename "${selected_compose_files[i]}")
              isOption "$((i + 1)). $compose_file_name"
            done

            # Read user input for file selection
            echo ""
            isQuestion "Enter the numbers of the files to edit (or 'x' to exit): "
            read -p "" selected_files

            case "$selected_files" in
              [0-9]*)
                # Edit the selected Docker Compose files with nano
                IFS=' ' read -ra selected_file_numbers <<< "$selected_files"
                for file_number in "${selected_file_numbers[@]}"; do
                  local index=$((file_number - 1))
                  if ((index >= 0 && index < ${#selected_compose_files[@]})); then
                    local selected_file="${selected_compose_files[index]}"
                    #echo "Debug: Editing file $selected_file"
                    sudo nano "$selected_file"
                  fi
                done
                ;;
              x)
                isNotice "Debug: Exiting..."
                return
                ;;
              *)
                isNotice "Debug: Invalid option. Please choose valid file numbers or 'x' to exit."
                ;;
            esac
          done
        fi
      else
        isNotice "Invalid app number. Please choose a valid option."
      fi
      ;;
    x)
      isNotice "Exiting..."
      return
      ;;
    *)
      isNotice "Invalid option. Please choose a valid option or 'x' to exit."
      ;;
  esac
}

viewConfigs() 
{
    while true; do
        echo ""
        echo "#################################"
        echo "###    Manage Config Files    ###"
        echo "#################################"
        echo ""
        isOption "1. EasyDocker configs"
        isOption "2. App configs"
        echo ""
        isQuestion "Please select an option (1 or 2, or 'x' to exit): "
        read -p "" view_config_option
        case "$view_config_option" in
        1)
            viewEasyDockerConfigs
            ;;
        2)
            viewAppConfigs
            ;;
        x)
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for all Configs."
                echo ""
                loadFiles "easydocker_configs";
                loadFiles "app_configs";
            else
                isNotice "Exiting..."
                echo ""
                checkConfigFilesMissingVariables true;
                databaseCycleThroughListAppsCrontab true;
                return
            fi
            ;;
        *)
            isNotice "Invalid option. Please choose a valid option or 'x' to exit."
            ;;
        esac
    done
}

viewAppConfigs() 
{
    while true; do
        echo ""
        echo "#################################"
        echo "###        App Categories     ###"
        echo "#################################"
        echo ""
        isOption "1. System Apps"
        isOption "2. Privacy Apps"
        isOption "3. User Apps"
        echo ""
        isQuestion "Please select an option (1/2/3 or 'x' to exit): "
        read -p "" view_app_category_option
        case "$view_app_category_option" in
        1)
            viewAppCategoryConfigs "system"
            ;;
        2)
            viewAppCategoryConfigs "privacy"
            ;;
        3)
            viewAppCategoryConfigs "user"
            ;;
        x)
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for Applications."
                echo ""
                loadFiles "app_configs";
            else
                isNotice "Exiting..."
                return
            fi
            ;;
        *)
            isNotice "Invalid selection. Please choose a valid category or 'x' to exit."
            ;;
        esac
    done
}

viewAppCategoryConfigs() 
{
    local category="$1"

    if [[ -z "$category" ]]; then
        echo "Usage: viewAppCategoryConfigs <category>"
        return 1
    fi

    local installed_apps=()
    local other_apps=()

    # Collect all app_name folders and categorize them into installed and others
    for app_dir in "$containers_dir"/*/; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            local app_config_file="$install_containers_dir$app_name/$app_name.sh"
            if [ -f "$app_config_file" ]; then
                local category_info=$(grep -Po '(?<=# Category : ).*' "$app_config_file")
                if [ "$category_info" == "$category" ]; then
                    # Check if the app_name is installed based on the database query
                    results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
                    if [[ -n "$results" ]]; then
                        installed_apps+=("$app_name *INSTALLED")
                    else
                        other_apps+=("$app_name")
                    fi
                fi
            fi
        fi
    done

    if [[ ${#installed_apps[@]} -eq 0 && ${#other_apps[@]} -eq 0 ]]; then
        echo "No app_name folders found in category '$category'."
        return 1
    fi

    local category_name="$category"
    local category_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${category_name:0:1})${category_name:1}"

    echo ""
    echo "#################################"
    echo "###    $category_name_ucfirst Applications"
    echo "#################################"

    PS3="Select an application: "

    select_app=""

    while [[ -z "$select_app" ]]; do
        echo ""
        # Display *INSTALLED* apps first and then others
        for ((i = 0; i < ${#installed_apps[@]}; i++)); do
            local app_option="${installed_apps[i]}"
            isOption "$((i + 1)). $app_option"
        done

        for ((i = 0; i < ${#other_apps[@]}; i++)); do
            local app_option="${other_apps[i]}"
            isOption "$((i + 1 + ${#installed_apps[@]})). $app_option"
        done
        
        echo ""
        isQuestion "Enter the number of the app to edit or 'b' to go back or 'x' to exit: "
        read -p "" selected_number
        
        if [[ "$selected_number" == "b" ]]; then
            return
        elif [[ "$selected_number" == "x" ]]; then
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for all Applications."
                echo ""
                loadFiles "app_configs";
                resetToMenu;
            else
                resetToMenu;
            fi
        elif [[ "$selected_number" =~ ^[0-9]+$ ]]; then
            if ((selected_number >= 1 && selected_number <= (${#installed_apps[@]} + ${#other_apps[@]}))); then
                if ((selected_number <= ${#installed_apps[@]})); then
                    # Selected an *INSTALLED* app
                    local selected_index=$((selected_number - 1))
                    local app_option="${installed_apps[selected_index]}"
                else
                    # Selected an app from the other category
                    local selected_index=$((selected_number - ${#installed_apps[@]} - 1))
                    local app_option="${other_apps[selected_index]}"
                fi

                # Remove the "*INSTALLED" suffix if it's present
                local app_name="${app_option%% *INSTALLED}"
                editAppConfig "$app_name"
                local select_app="$app_name"
            else
                isNotice "Invalid number. Please select a valid number or 'x' to exit."
                echo ""
                read -p "Press Enter to continue."
            fi
        else
            isNotice "Invalid input. Please enter a valid number or 'x' to exit."
            echo ""
            read -p "Press Enter to continue."
        fi
    done
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

scanConfigsFixLineEnding()
{
    for app_name_dir in "$container_dir"/*/; do
        if [ -d "$app_name_dir" ]; then
            for config_file in "$app_name_dir"/*.config; do
                if [[ -f "$config_file" ]]; then
                    # Check if the file doesn't end with a newline character
                    if [[ $(tail -c 1 "$config_file" | wc -l) -eq 0 ]]; then
                        echo >> "$config_file"  # Add a newline character to the end of the file
                    fi
                fi
            done
        fi
    done
}
