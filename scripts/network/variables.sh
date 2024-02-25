#!/bin/bash

# Default install variable setups
setupInstallVariables()
{
    app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    host_name_var="CFG_${app_name^^}_HOST_NAME"
    compose_setup_var="CFG_${app_name^^}_COMPOSE_FILE"
    domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"
    public_var="CFG_${app_name^^}_PUBLIC"
    whitelist_var="CFG_${app_name^^}_WHITELIST"
    login_required_var="CFG_${app_name^^}_LOGIN_REQUIRED"
    authelia_var="CFG_${app_name^^}_AUTHELIA"
    headscale_var="CFG_${app_name^^}_HEADSCALE"

    # Access the variables using variable indirection
    host_name="${!host_name_var}"
    compose_setup="${!compose_setup_var}"
    domain_number="${!domain_number_var}"
    public="${!public_var}"
    whitelist="${!whitelist_var}"
    login_required="${!login_required_var}"
    authelia_setup="${!authelia_var}"
    headscale_setup="${!authelia_var}"

    # Default Empty config options
    if [ "$authelia_setup" == "" ]; then
        authelia_setup=false
    fi
    if [ "$headscale_setup" == "" ]; then
        headscale_setup=false
    fi
    if [ "$whitelist" == "" ]; then
        whitelist=false
    fi
    if [ "$login_required" == "" ]; then
        login_required=false
    fi
    if [ "$public" == "" ]; then
        public=false
    fi

    # Check if no network needed
    if [ "$host_name" != "" ]; then
        setupIPsAndHostnames $app_name;
    fi 
}

# All network variables setup
setupIPsAndHostnames()
{
    found_match=false
    while read -r line; do
        local hostname=$(echo "$line" | awk '{print $1}')
        local ip=$(echo "$line" | awk '{print $2}')
        
        if [ "$hostname" = "$host_name" ]; then
            found_match=true
            # Public variables
            domain_prefix=$hostname
            domain_var_name="CFG_DOMAIN_${domain_number}"
            domain_full=$(sudo grep  "^$domain_var_name=" $configs_dir/config_general | cut -d '=' -f 2-)
            host_setup=${domain_prefix}.${domain_full}
            ssl_key=${domain_full}.key
            ssl_crt=${domain_full}.crt
            ip_setup=$ip

            clearAllPortData;
            
            # Generates port variables: usedport1, usedport2, etc.
            used_ports_var="CFG_${app_name^^}_PORTS"
            used_initial_ports="${!used_ports_var}"
            if [ -n "$used_initial_ports" ]; then
                IFS=',' read -ra usedports <<< "$used_initial_ports"
                for i in "${!usedports[@]}"; do
                    used_variable_name="usedport$((i+1))"
                    eval "$used_variable_name=${usedports[i]}"
                done
            fi

            # Generates port variables: openport1, openport2, etc.
            open_ports_var="CFG_${app_name^^}_OPEN_PORTS"
            open_initial_ports="${!open_ports_var}"
            if [ -n "$open_initial_ports" ]; then
                IFS=',' read -ra openports <<< "$open_initial_ports"
                for i in "${!openports[@]}"; do
                    local open_variable_name="openport$((i+1))"
                    eval "$open_variable_name=${openports[i]}"
                done
            fi

        fi
    done < "$configs_dir$ip_file"
    
    if ! "$found_match"; then  # Changed the condition to check if no match is found
        isError "No matching hostnames found for $host_name, please fill in the ips_hostname file"
        resetToMenu;
    fi
}

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
}

setupScanVariables()
{
    app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    compose_setup_var="CFG_${app_name^^}_COMPOSE_FILE"
    compose_setup="${!compose_setup_var}"

    clearAllPortData;
    
    # Generates port variables: usedport1, usedport2, etc.
    used_ports_var="CFG_${app_name^^}_PORTS"
    used_initial_ports="${!used_ports_var}"
    if [ -n "$used_initial_ports" ]; then
        IFS=',' read -ra usedports <<< "$used_initial_ports"
        for i in "${!usedports[@]}"; do
            used_variable_name="usedport$((i+1))"
            eval "$used_variable_name=${usedports[i]}"
        done
    fi

    # Generates port variables: openport1, openport2, etc.
    open_ports_var="CFG_${app_name^^}_OPEN_PORTS"
    open_initial_ports="${!open_ports_var}"
    if [ -n "$open_initial_ports" ]; then
        IFS=',' read -ra openports <<< "$open_initial_ports"
        for i in "${!openports[@]}"; do
            local open_variable_name="openport$((i+1))"
            eval "$open_variable_name=${openports[i]}"
        done
    fi
}
