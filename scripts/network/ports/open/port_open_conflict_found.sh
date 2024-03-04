#!/bin/bash

portOpenConflictFound() 
{
    local app_name="$1"

    if [ -n "$app_name" ]; then
        # Iterate through the array to find conflicts for the specific app_name
        for openconflict in "${openPortConflicts[@]}"; do
            if [[ "$openconflict" == *"$app_name"* ]]; then
                echo ""
                echo "###############################################"
                echo "######    Open Port Conflict(s) Found    ######"
                echo "###############################################"
                echo ""
                isNotice "Open port conflicts have been found for $app_name:"
                echo ""
                local conflicts_without_app_name="${openconflict/$app_name /}"  
                isError "$conflicts_without_app_name"

                while true; do
                    echo ""
                    isNotice "Please edit the ports in the configuration file for $app_name."
                    echo ""
                    isQuestion "Would you like to edit the config for $app_name? (y/n): "
                    read -p "" openportconfigedit_choice
                    if [[ -n "$openportconfigedit_choice" ]]; then
                        if [[ "$openportconfigedit_choice" =~ [yY] ]]; then
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
