#!/bin/bash

setupHeadscaleVariables()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    headscale_host_name_var="CFG_${app_name^^}_HOST_NAME"
    headscale_domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"
    headscale_setup_var="CFG_${app_name^^}_HEADSCALE"

    # Access the variables using variable indirection
    headscale_host_name="${!headscale_host_name_var}"
    headscale_domain_number="${!headscale_domain_number_var}"
    headscale_setup="${!headscale_setup_var}"

    # Check if no network needed
    if [ "$headscale_host_name" != "" ]; then
        while read -r line; do
            local headscale_hostname=$(echo "$line" | awk '{print $1}')
            local headscale_ip=$(echo "$line" | awk '{print $2}')
            if [ "$headscale_hostname" = "$headscale_host_name" ]; then
                headscale_domain_prefix=$headscale_hostname
                headscale_domain_var_name="CFG_DOMAIN_${headscale_domain_number}"
                headscale_domain_full=$(sudo grep  "^$headscale_domain_var_name=" $configs_dir/config_general | cut -d '=' -f 2-)
                headscale_host_setup=${headscale_domain_prefix}.${headscale_domain_full}
                headscale_ip_setup=$headscale_ip
            fi
        done < "$configs_dir$ip_file"
    fi 
}
