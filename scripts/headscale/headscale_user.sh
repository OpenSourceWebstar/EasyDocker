#!/bin/bash

setupHeadscaleUser()
{
    local app_name="$1"
    local local_type="$2"
    
    isNotice "Setting up Headscale for $app_name"
    
    if [[ "$app_name" == "localhost" ]]; then
        setupHeadscaleLocalhost $local_type;
    fi

    if [[ "$headscale_setup" == *"local"* ]]; then
        setupHeadscaleLocal $app_name;
    fi

    if [[ "$headscale_setup" == *"remote"* ]]; then
        if setupHeadscaleCheckRemote; then
            setupHeadscaleRemote $app_name;
        fi
    fi

    if [[ "$headscale_setup" == "" ]]; then
        echo ""
        isNotice "Headscale is no setup for $app_name."
        isNotice "Please setup the config"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi
}
