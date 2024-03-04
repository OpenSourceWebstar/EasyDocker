#!/bin/bash

portUsedConflictFound() 
{
    local app_name="$1"

    if [ -n "$app_name" ]; then
        # Iterate through the array to find conflicts for the specific app_name
        for usedconflict in "${portConflicts[@]}"; do
            if [[ "$usedconflict" == *"$app_name"* ]]; then
                echo ""
                echo "##########################################"
                echo "######    Port Conflict(s) Found    ######"
                echo "##########################################"
                echo ""
                isNotice "Port conflicts have been found for $app_name:"
                echo ""
                local conflicts_without_app_name="${usedconflict/$app_name /}"  
                isError "$conflicts_without_app_name"

                while true; do
                    echo ""
                    isNotice "Please edit the ports in the configuration file for $app_name."
                    echo ""
                    isQuestion "Would you like to edit the config for $app_name? (y/n): "
                    read -p "" portconfigedit_choice
                    if [[ -n "$portconfigedit_choice" ]]; then
                        if [[ "$portconfigedit_choice" =~ [yY] ]]; then
                            editAppConfig "$app_name"
                        fi
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
            fi
        done
    fi
}
