#!/bin/bash

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

            portClearAllData;
            
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
