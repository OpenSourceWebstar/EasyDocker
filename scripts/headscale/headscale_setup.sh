#!/bin/bash

setupHeadscale() 
{
    local app_name="$1"
    local local_type="$2"

    if [ "$app_name" != "localhost" ]; then
        setupHeadscaleVariables "$app_name"
    fi

    local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
    local status=$(dockerCheckAppInstalled "headscale" "docker")

    if [ "$status" == "installed" ]; then
        # We don't set up headscale for headscale
        if [[ "$app_name" == "headscale" ]]; then
            dockerCommandRun "docker exec headscale headscale users create $CFG_INSTALL_NAME"
            checkSuccess "Creating Headscale user $CFG_INSTALL_NAME"

            while true; do
                echo ""
                isQuestion "Would you like to connect your localhost client to the Headscale server? (y/n) "
                read -p "" local_headscale
                if [[ -n "$local_headscale" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done

            if [[ "$local_headscale" == [yY] ]]; then
                setupHeadscaleUser localhost local
            fi
        elif [[ "$app_name" == "localhost" ]]; then
            while true; do
                echo ""
                isQuestion "Would you like to set up your localhost Headscale client to Localhost or Remote? (l/r) "
                read -p "" localhost_type_headscale
                if [[ -n "$localhost_type_headscale" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done

            if [[ "$localhost_type_headscale" == [lL] ]]; then
                setupHeadscaleUser localhost local
            elif [[ "$localhost_type_headscale" == [rR] ]]; then
                setupHeadscaleUser localhost remote
            fi
        else
            if [[ "$headscale_setup" != "disabled" ]]; then
                setupHeadscaleUser "$app_name"
            elif [[ "$headscale_setup" == "disabled" || "$headscale_setup" == "" ]]; then
                isNotice "Headscale is not enabled for $app_name, unable to install."
            fi
        fi
    else
        isSuccessful "Headscale is not installed."
    fi
}
