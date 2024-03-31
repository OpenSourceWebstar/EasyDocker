#!/bin/bash

setupBasicAppVariable()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    app_host_name_var="CFG_${app_name^^}_HOST_NAME"
    app_domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"
    app_public_var="CFG_${app_name^^}_PUBLIC"

    # Access the variables using variable indirection
    app_host_name="${!app_host_name_var}"
    app_domain_number="${!app_domain_number_var}"
    app_public="${!app_public_var}"

    if [ "$app_public" == "" ]; then
        app_public=false
    fi

    # Check if no network needed
    if [ "$app_host_name" != "" ]; then
        while read -r line; do
            local app_hostname=$(echo "$line" | awk '{print $1}')
            local app_ip=$(echo "$line" | awk '{print $2}')
            if [ "$app_hostname" = "$app_host_name" ]; then
                # Public variables
                app_domain_prefix=$app_hostname
                app_domain_var_name="CFG_DOMAIN_${app_domain_number}"
                app_domain_full=$(sudo grep  "^$app_domain_var_name=" $configs_dir/config_general | cut -d '=' -f 2-)
                app_host_setup=${app_domain_prefix}.${app_domain_full}

                if [ "$app_public" == "false" ]; then
                    app_ip_setup=$app_ip

                    # Clears the app_usedport1 variable
                    unset app_usedport1
                    
                    # Generates port variables: app_usedport1
                    app_used_ports_var="CFG_${app_name^^}_PORTS"
                    app_used_initial_ports="${!app_used_ports_var}"
                    if [ -n "$app_used_initial_ports" ]; then
                        IFS=',' read -ra app_usedports <<< "$app_used_initial_ports"
                        # Create only app_usedport1
                        app_used_variable_name="app_usedport1"
                        eval "$app_used_variable_name=${app_usedports[0]}"
                    fi
                fi
            fi
        done < "$configs_dir$ip_file"
    fi

    # Docker Type username
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        docker_install_user="$sudo_user_name"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        docker_install_user="$CFG_DOCKER_INSTALL_USER"
    fi
}
