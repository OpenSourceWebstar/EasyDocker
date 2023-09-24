#!/bin/bash

setupInstallVariables()
{
    app_name="$1"
    echo "setupInstallVariables"
    # Build variable names based on app_name
    host_name_var="CFG_${app_name^^}_HOST_NAME"
    domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"
    public_var="CFG_${app_name^^}_PUBLIC"
    port_var="CFG_${app_name^^}_PORT"
    port_2_var="CFG_${app_name^^}_PORT_2"

    #echo "host_name_var = $host_name_var"

    # Access the variables using variable indirection
    host_name="${!host_name_var}"
    domain_number="${!domain_number_var}"
    public="${!public_var}"
    port="${!port_var}"
    port_2="${!port_2_var}"

    #echo "host_name=$host_name"

    setupIPsAndHostnames;
}

setupIPsAndHostnames()
{
    # Check if no network needed
    if [ "$host_name" = "" ]; then
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
                
                if [[ "$public" == "true" ]]; then
                    isSuccessful "Using $host_setup for public domain."
                    checkSuccess "Match found: $hostname with IP $ip."  # Moved this line inside the conditional block
                    echo ""
                fi
            fi
        done < "$configs_dir$ip_file"
        
        if ! "$found_match"; then  # Changed the condition to check if no match is found
            checkSuccess "No matching hostnames found for $host_name, please fill in the ips_hostname file"
            echo ""
        fi
    fi
}

portExistsInDatabase()
{
    local app_name="$1"
    local port="$2"
    local type="$3"

    if [ -f "$base_dir/$db_file" ] && [ -n "$app_name" ]; then
        table_name=ports
        existing_portdata=$(sudo sqlite3 "$base_dir/$db_file" "SELECT port FROM $table_name WHERE port = '$port' AND type = '$type';")
        if [ -n "$existing_portdata" ]; then
            return 0  # Port exists in the database
        fi
    fi
    return 1  # Port does not exist in the database
}

openAppPorts()
{
    local app_name="$1"
    
    if [[ "$app_name" == "traefik" ]] || [[ "$app_name" == "caddy" ]]; then
        openPort $app_name 80/tcp
        openPort $app_name 443/tcp
    elif [[ "$app_name" == "wireguard" ]]; then
        openPort $app_name 51820/udp
    elif [[ "$app_name" == "jitsimeet" ]]; then
        openPort jitsimeet-jvb-1 10000/udp
        openPort jitsimeet-jvb-1 4443
    else
        isNotice "No ports needed to be opened."
    fi
}

openPort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw

    IFS='/' read -r port type <<< "$portdata"

    # Check if the port already exists in the database
    if portExistsInDatabase "$app_name" "$port" "$type"; then
        isNotice "Port $port and type $type already opened."
        return
    fi

    databasePortInsert "$app_name" "$portdata"

    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(sudo ufw allow "$port")
        checkSuccess "Opening port $port for $app_name in the UFW Firewall"
    elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        result=$(sudo ufw-docker allow "$app_name" "$port")
        checkSuccess "Opening port $port for $$app_name in the UFW-Docker Firewall"
    fi
}

closePort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw

    IFS='/' read -r port type <<< "$portdata"

    # Check if the port already exists in the database
    if portExistsInDatabase "$app_name" "$port" "$type"; then
        databasePortRemove "$app_name" "$portdata"
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(sudo ufw deny "$port")
            checkSuccess "Closing port $port for $app_name in the UFW Firewall"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo ufw-docker deny "$app_name" "$port")
            checkSuccess "Closing port $port for $$app_name in the UFW-Docker Firewall"
        fi
    else
        isNotice "Unable to find port in the database...skipping..."
    fi


}

CloseAppPorts()
{
    local app_name="$1"

    if [[ "$app_name" == "traefik" ]] || [[ "$app_name" == "caddy" ]]; then
        closePort $app_name 80/tcp
        closePort $app_name 443/tcp
    elif [[ "$app_name" == "wireguard" ]]; then
        closePort $app_name 51820/udp
    elif [[ "$app_name" == "jitsimeet" ]]; then
        closePort jitsimeet-jvb-1 10000/udp
        closePort jitsimeet-jvb-1 4443
    else
        isNotice "No ports needed to be closed."
    fi
}

sshRemote() 
{
    local ssh_pass="$1"
    local ssh_port="$2"
    local ssh_login="$3"
    local ssh_command="$4"

    # Run the SSH command using the existing SSH variables
    sudo sshpass -p "$ssh_pass" sudo ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $ssh_port $ssh_login $ssh_command
    #checkSuccess "Running Remote SSH Command : $ssh_command"
}