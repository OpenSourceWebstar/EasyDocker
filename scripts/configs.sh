#!/bin/bash

##!/bin/bash

# Function to check missing config variables in local config files against remote config files
checkConfigFilesMissingVariables()
{
    local local_configs=("$configs_dir"config_*)
    remote_config_dir="https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/configs/"
    
    # Find all .config files within the $container_dir directory and its subfolders
    container_configs=($(find "$containers_dir" -type f -name '*.config'))
    
    # Loop through all config files
    for local_config_file in "${local_configs[@]}" "${container_configs[@]}"; do
        local_config_filename=$(basename "$local_config_file")
        
        # Extract config variables from the local file
        local_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$local_config_file" | sed 's/=$//'))
        
        # Generate the remote URL based on the local config file name
        remote_url="$remote_config_dir$local_config_filename"
        
        # Download the remote config file
        tmp_file=$(mktemp)
        curl -s "$remote_url" -o "$tmp_file"
        
        # Extract config variables from the remote file
        remote_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$tmp_file" | sed 's/=$//'))
        
        # Filter out empty variable names from the remote variables
        remote_variables=("${remote_variables[@]//[[:space:]]/}")  # Remove whitespace
        remote_variables=($(echo "${remote_variables[@]}" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' '))
        
        # Compare local and remote variables
        for remote_var in "${remote_variables[@]}"; do
            if ! [[ " ${local_variables[@]} " =~ " $remote_var " ]]; then
                var_line=$(grep "${remote_var}=" "$tmp_file")
                
                echo ""
                echo "########################################"
                echo "###   Missing Config Variable Found  ###"
                echo "########################################"
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
                        echo "$var_line" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                        checkSuccess "Adding the $var_line to '$local_config_filename':"
                    ;;
                    2)
                        echo ""
                        isQuestion "Enter your value for $remote_var: "
                        read -p " " custom_value
                        echo ""
                        echo "CFG_${remote_var}=$custom_value" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                        checkSuccess "Adding the CFG_${remote_var}=$custom_value to '$local_config_filename':"
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
        
        # Clean up the temporary file
        rm "$tmp_file"
    done
    
    echo ""
    isSuccessful "Config variable check completed."  # Indicate completion
}

checkConfigFilesExist()
{
    if [[ $CFG_REQUIREMENT_CONFIG == "true" ]]; then
        local file_found_count=0
        
        for file in "${config_files_all[@]}"; do
            if [ -f "$configs_dir/$file" ]; then
                ((file_found_count++))
            else
                isFatalError "Config File $file does not exist in $configs_dir."
                isFatalErrorExit "Please make sure all configs are present"
            fi
        done
        
        if [ "$file_found_count" -eq "${#config_files_all[@]}" ]; then
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

editAppConfig() {
    local app_name="$1"
    local config_file
    local app_dir

    if [[ "$app_name" == "" ]]; then
        return
    fi

    # Use find to search for the app_name folder within $containers_dir
    app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)

    if [ -n "$app_dir" ]; then
        config_file="$app_dir/$app_name.config"

        if [ -f "$config_file" ]; then
            # Calculate the checksum of the original file
            original_checksum=$(md5sum "$config_file")

            # Open the file with nano for editing
            nano "$config_file"

            # Calculate the checksum of the edited file
            edited_checksum=$(md5sum "$config_file")

            # Compare the checksums to check if changes were made
            if [[ "$original_checksum" != "$edited_checksum" ]]; then
                # Ask the user if they want to reinstall the application
                while true; do
                    isQuestion "Changes have been made to the $app_name configuration. Do you want to reinstall the $app_name application? (y/n): "
                    read -p "" reinstall_choice
                    if [[ -n "$reinstall_choice" ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
                if [[ "$reinstall_choice" =~ [yY] ]]; then
                    # Convert the first letter of app_name to uppercase
                    app_name_ucfirst="$(tr '[:lower:]' '[:upper:]' <<< ${app_name:0:1})${app_name:1}"
                    installFuncName="install${app_name_ucfirst}"
                    if type "$installFuncName" &>/dev/null; then
                        variable_name="$app_name"
                        declare "$variable_name=i"
                        "$installFuncName" 
                    else
                        isNotice "Installation function not found for $app_name."
                    fi
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
            
            isOption "$first_letter. ${config_name,,} (Last modified: $formatted_last_modified)"
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
            echo ""
            isNotice "Exiting."
            return
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
            isNotice "Exiting."
            return
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

    local category_dir="$containers_dir/$category"

    if [[ ! -d "$category_dir" ]]; then
        echo "Category '$category' does not exist in '$containers_dir'."
        return 1
    fi

    local installed_apps=()
    local other_apps=()

    # Collect all app_name folders and categorize them into installed and others
    while IFS= read -r -d $'\0' app_name_dir; do
        app_name=$(basename "$app_name_dir")
        # Check if the app_name is installed based on the database query
        results=$(sudo sqlite3 "$base_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
        if [[ -n "$results" ]]; then
            installed_apps+=("$app_name *INSTALLED")
        else
            other_apps+=("$app_name")
        fi
    done < <(find "$category_dir" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ ${#installed_apps[@]} -eq 0 && ${#other_apps[@]} -eq 0 ]]; then
        echo "No app_name folders found in category '$category'."
        return 1
    fi

    local category_name=$(basename "$category_dir")
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
            app_option="${installed_apps[i]}"
            isOption "$((i + 1)). $app_option"
        done

        for ((i = 0; i < ${#other_apps[@]}; i++)); do
            app_option="${other_apps[i]}"
            isOption "$((i + 1 + ${#installed_apps[@]})). $app_option"
        done
        
        echo ""
        isQuestion "Enter the number of the app to edit or 'b' to go back or 'x' to exit: "
        read -p "" selected_number
        
        if [[ "$selected_number" == "b" ]]; then
            return
        elif [[ "$selected_number" == "x" ]]; then
            isNotice "Exiting."
            resetToMenu;
        elif [[ "$selected_number" =~ ^[0-9]+$ ]]; then
            if ((selected_number >= 1 && selected_number <= (${#installed_apps[@]} + ${#other_apps[@]}))); then
                if ((selected_number <= ${#installed_apps[@]})); then
                    # Selected an *INSTALLED* app
                    selected_index=$((selected_number - 1))
                    app_option="${installed_apps[selected_index]}"
                else
                    # Selected an app from the other category
                    selected_index=$((selected_number - ${#installed_apps[@]} - 1))
                    app_option="${other_apps[selected_index]}"
                fi

                # Remove the "*INSTALLED" suffix if it's present
                app_name="${app_option%% *INSTALLED}"
                editAppConfig "$app_name"
                select_app="$app_name"
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