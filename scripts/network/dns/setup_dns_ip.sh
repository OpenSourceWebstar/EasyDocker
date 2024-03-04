#!/bin/bash

setupDNSIP()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    dns_host_name_var="CFG_${app_name^^}_HOST_NAME"

    # Access the variables using variable indirection
    dns_host_name="${!dns_host_name_var}"

    # Check if no network needed
    if [ "$dns_host_name" != "" ]; then
        while read -r line; do
            local dns_hostname=$(echo "$line" | awk '{print $1}')
            local dns_ip=$(echo "$line" | awk '{print $2}')
            if [ "$dns_hostname" = "$dns_host_name" ]; then
                dns_ip_setup=$dns_ip
            fi
        done < "$configs_dir$ip_file"
    fi 
}
