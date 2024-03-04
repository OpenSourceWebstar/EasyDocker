#!/bin/bash

dockerCheckAllowedInstall() 
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
                dockerUninstallApp "$app_name"
                return 1
            fi
            ;;
        #"mailcow")
            #local status=$(dockerCheckAppInstalled "webmin" "linux" "check_active")
            #if [ "$status" == "installed" ]; then
                #isError "Virtualmin is installed, this will conflict with $app_name."
                #isError "Installation is now aborting..."
                #dockerUninstallApp "$app_name"
                #return 1
            #elif [ "$status" == "running" ]; then
                #isError "Virtualmin is installed, this will conflict with $app_name."
                #isError "Installation is now aborting..."
                #dockerUninstallApp "$app_name"
                #return 1
            #fi
            #;;
        #"virtualmin")
            #local status=$(dockerCheckAppInstalled "webmin" "linux" "check_active")
            #if [ "$status" == "not_installed" ]; then
              #isError "Virtualmin is not installed or running, it is required."
              #dockerUninstallApp "$app_name"
              #return 1
            #elif [ "$status" == "invalid_flag" ]; then
              #isError "Invalid flag provided..cancelling install..."
              #dockerUninstallApp "$app_name"
              #return 1
            #fi
            #local status=$(dockerCheckAppInstalled "traefik" "docker")
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
                    #dockerInstallApp traefik;
                #fi
                #if [[ "$virtualmin_traefik_choice" == [nN] ]]; then
                    #isError "Installation is now aborting..."
                    #dockerUninstallApp "$app_name"
                    #return 1
                #fi
            #elif [ "$status" == "invalid_flag" ]; then
              #isError "Invalid flag provided..cancelling install..."
              #dockerUninstallApp "$app_name"
              #return 1
            #fi
            #;;
    esac

    isSuccessful "Application is allowed to be installed."
}
