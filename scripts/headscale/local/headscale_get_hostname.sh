#!/bin/bash

setupHeadscaleGetHostname()
{
    local config_file="${containers_dir}headscale/config/config.yaml"
    if [ -f "$config_file" ]; then
        # Read the line with "server_url" and extract the hostname
        headscale_live_hostname=$(grep "server_url:" "$config_file" | awk -F'server_url: ' '{print $2}')

        # Check if the hostname was found
        if [ -n "$headscale_live_hostname" ]; then
            isSuccessful "Hostname for Headscale found: $headscale_live_hostname"
        else
            isError "Hostname not found in $config_file."
        fi
    else
        isError "Headscale config File $config_file not found."
    fi
}
