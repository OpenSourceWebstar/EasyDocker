#!/bin/bash

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

            # Open the file with $CFG_TEXT_EDITOR for editing
            sudo $CFG_TEXT_EDITOR "$config_file"

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
                    dockerInstallApp $app_name;
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
