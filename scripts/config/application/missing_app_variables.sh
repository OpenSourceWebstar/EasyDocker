#!/bin/bash

checkApplicationsConfigFilesMissingVariables() 
{
    #isNotice "Scanning Application config files...please wait"
    local container_configs=($(sudo find "$containers_dir" -maxdepth 2 -type f -name '*.config'))  # Find .config files in immediate subdirectories of $containers_dir

    for container_config_file in "${container_configs[@]}"; do
        local container_config_filename=$(basename "$container_config_file")
        local config_app_name="${container_config_filename%.config}"

        # Extract config variables from the local file
        local local_variables=($(sudo grep -o 'CFG_[A-Za-z0-9_]*=' "$container_config_file" | sudo sed 's/=$//'))

        # Find the corresponding .config file in $install_containers_dir
        local remote_config_file="$install_containers_dir$config_app_name/$config_app_name.config"

        if [ -f "$remote_config_file" ]; then

            # Extract config variables from the remote file
            local remote_variables=($(sudo grep -o 'CFG_[A-Za-z0-9_]*=' "$remote_config_file" | sudo sed 's/=$//'))

            # Filter out empty variable names from the remote variables
            local remote_variables=("${remote_variables[@]//[[:space:]]/}")  # Remove whitespace
            local remote_variables=($(echo "${remote_variables[@]}" | tr ' ' '\n' | sudo grep -v '^$' | tr '\n' ' '))

            # Compare local and remote variables
            for remote_var in "${remote_variables[@]}"; do
                if ! [[ " ${local_variables[@]} " =~ " $remote_var " ]]; then
                    local var_line=$(sudo grep "${remote_var}=" "$remote_config_file")

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
                                                dockerComposeUpdateAndStartApp $config_app_name restart;
                                                echo ""
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
                                                dockerInstallApp $config_app_name;
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
                                                dockerComposeUpdateAndStartApp $config_app_name restart;
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
                                                dockerInstallApp $config_app_name;
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
