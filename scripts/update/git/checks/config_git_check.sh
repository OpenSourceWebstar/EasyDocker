#!/bin/bash

gitCheckConfigs() 
{
    if sudo grep -q "Change-Me" "$configs_dir/$config_file_general"; then
        #echo "Local configuration file contains 'Change-Me'."
        # Flag to track if any valid configs were found
        local valid_configs_found=false

        # Get a list of all backup zip files in the directory, sorted by date (latest first)
        local backup_files=($(sudo find "$backup_dir" -type f -name 'backup_*.zip' | sort -r))
        
        # Check if any backup files were found
        if [ ${#backup_files[@]} -eq 0 ]; then
            echo ""
            echo "#####################################"
            echo "###    Welcome to EasyDocker :)   ###"
            echo "#####################################"
            echo ""
            isNotice "It looks like this is first time installing EasyDocker on this system."
            echo ""
            isNotice "If this is a fresh install, continue on..."
            isNotice "If you were trying to restore any config backups, nothing was found."
            echo ""
            while true; do
                isQuestion "Do you want to continue? (y/n): "
                read -rp " " acceptnoconfigs
                if [[ "$acceptnoconfigs" =~ ^[yY]$ ]]; then
                    break
                elif [[ "$acceptnoconfigs" =~ ^[nN]$ ]]; then
                    echo ""
                    echo ""
                    isNotice "Place your EasyDocker install backup file into $backup_dir and run the 'easydocker' command."
                    exitScript
                    exit;
                else
                    isNotice "Please provide a valid input (y/n)."
                fi
            done
            return
        fi

        for zip_file in "${backup_files[@]}"; do
            #echo "Processing backup file: $zip_file"
            # Create a temporary directory to extract the zip file contents
            local temp_dir=$(mktemp -d)

            # Extract the zip file contents
            unzip -q "$zip_file" -d "$temp_dir"

            # Find the path of $config_file_general within the extracted files
            local config_file_path=$(sudo find "$temp_dir" -type f -name "$config_file_general")

            # Check if $config_file_general exists and does not contain "Change-Me"
            if [ -n "$config_file_path" ] && ! grep -q "Change-Me" "$config_file_path"; then
                local valid_configs_found=true
                isSuccessful "Valid config found in backup file: $zip_file"
                while true; do
                    isQuestion "Do you want to restore the latest config backup? (y/n): "
                    read -p "" defaultconfigfound
                    case $defaultconfigfound in
                        [yY])
                            gitUseExistingBackup $zip_file
                            # Set the flag to exit the loop
                            break 2  # Exit the outer loop as well
                            ;;
                        [nN])
                            isNotice "Custom changes will be kept, continuing..."
                            break
                            ;;
                        *)
                            isNotice "Please provide a valid input (y or n)."
                            ;;
                    esac
                done
            #else
                #echo "Config file not found or contains 'Change-Me' in backup file: $zip_file"
            fi

            # Clean up the temporary directory
            rm -rf "$temp_dir"
        done

        # If no valid configs were found in any backup file, display a message
        if [ "$valid_configs_found" = false ]; then
            if [[ $acceptupdates != [nN] ]]; then
                echo ""
                echo "#####################################"
                echo "###    Welcome to EasyDocker :)   ###"
                echo "#####################################"
                echo ""
                isNotice "It looks like this is first time installing EasyDocker on this system."
                echo ""
                isNotice "If this is a fresh install, continue on..."
                isNotice "If you were trying to restore any config backups, nothing was found."
                echo ""
                while true; do
                    isQuestion "Do you want to continue with the install? (y/n): "
                    read -rp "" acceptnoconfigs
                    if [[ "$acceptnoconfigs" =~ ^[yYnN]$ ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input (y/n)."
                done
                if [[ $acceptnoconfigs == [nN] ]]; then
                    echo ""
                    echo ""
                    isNotice "Place your EasyDocker install backup file into $backup_dir and run the 'easydocker' command."
                    exitScript
                    exit
                fi
            fi
        fi
    fi
}
