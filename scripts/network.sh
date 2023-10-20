#!/bin/bash

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
    authelia_var="CFG_${app_name^^}_AUTHELIA"

    # Access the variables using variable indirection
    host_name="${!host_name_var}"
    compose_setup="${!compose_setup_var}"
    domain_number="${!domain_number_var}"
    public="${!public_var}"
    whitelist="${!whitelist_var}"
    authelia_setup="${!authelia_var}"

    # Check if no network needed
    if [ "$host_name" != "" ]; then
        setupIPsAndHostnames $app_name;
    fi 
}

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
            
            # Setup all ports
            # Generates port variables: num_ports, openport1, openport2, etc.
            open_ports_var="CFG_${app_name^^}_OPEN_PORTS"
            open_initial_ports="${!open_ports_var}"

            # Generates port variables: num_ports, port1, port2, etc.
            used_ports_var="CFG_${app_name^^}_PORTS"
            used_initial_ports="${!used_ports_var}"
        fi
    done < "$configs_dir$ip_file"
    
    if ! "$found_match"; then  # Changed the condition to check if no match is found
        isError "No matching hostnames found for $host_name, please fill in the ips_hostname file"
        resetToMenu;
    fi
}

portExistsInDatabase()
{
    local app_name="$1"
    local port="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports
        local app_name_from_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM $table_name WHERE port = '$port';")

        if [ -n "$app_name_from_db" ]; then
            isError "Port $port is already used by $app_name_from_db."
            return 1  # Port exists in the database
        else
            isSuccessful "No open port found for $port...continuing..."
            return 0  # Port does not exist in the database
        fi
    fi
}
#scan for already installed apps & the ports they use and add them to the db
portOpenExistsInDatabase()
{
    local app_name="$1"
    local port="$2"
    local type="$3"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports_open
        local app_name_from_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM $table_name WHERE port = '$port' AND type = '$type';")

        if [ -n "$app_name_from_db" ]; then
            isError "Port $port and type $type is already open for $app_name_from_db."
            return 0  # Port exists in the database
        else
            isSuccessful "Port $port not open...continuing..."
            return 1  # Port does not exist in the database
        fi
    fi
}

checkAppPorts()
{
    local app_name="$1"

    # Open Ports
    # Check if open_initial_ports is not empty
    if [ -n "$open_initial_ports" ]; then
        # Split the configuration into an array using a comma as a delimiter
        IFS=',' read -ra openports <<< "$open_initial_ports"
        for i in "${!openports[@]}"; do
            local open_variable_name="openport$((i+1))"
            eval "$open_variable_name=${openports[i]}"
        done
    else
        isNotice "No ports found to open."
    fi

    if [ ${#openports[@]} -gt 0 ]; then
        for i in "${!openports[@]}"; do
            local open_variable_name="openport$((i+1))"
            local open_port_value="${!open_variable_name}"
            openPort "$app_name" "$open_port_value"
        done
    fi

    # Used Ports
    # Check if used_initial_ports is not empty
    if [ -n "$used_initial_ports" ]; then
        # Split the configuration into an array using a comma as a delimiter
        IFS=',' read -ra usedports <<< "$used_initial_ports"
        for i in "${!usedports[@]}"; do
            local used_variable_name="usedport$((i+1))"
            eval "$used_variable_name=${usedports[i]}"
        done
    else
        isNotice "No data found to log."
    fi

    if [ ${#usedports[@]} -gt 0 ]; then
        for i in "${!usedports[@]}"; do
            local used_variable_name="usedport$((i+1))"
            local used_port_value="${!used_variable_name}"
            logPort "$app_name" "$used_port_value"
        done
    fi

    isNotice "All ports have been added and opened (if required)."
}

logPort()
{
    local app_name="$1"
    local port="$2"

    # Check if the port already exists in the database
    if portExistsInDatabase "$app_name" "$port"; then
        return
    fi

    databasePortInsert "$app_name" "$port"
}

openPort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw

    IFS='/' read -r port type <<< "$portdata"

    # Check if the port already exists in the database
    if portOpenExistsInDatabase "$app_name" "$port" "$type"; then
        isNotice "Port $port and type $type already opened."
        return
    fi

    databasePortOpenInsert "$app_name" "$portdata"

    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        local result=$(sudo ufw allow "$port")
        checkSuccess "Opening port $port for $app_name in the UFW Firewall"
    elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
        local result=$(sudo ufw-docker allow "$app_name" "$port")
        checkSuccess "Opening port $port for $$app_name in the UFW-Docker Firewall"
    fi
}

closePort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw

    IFS='/' read -r port type <<< "$portdata"

    # Check if the port already exists in the database
    if portOpenExistsInDatabase "$app_name" "$port" "$type"; then
        databasePortOpenRemove "$app_name" "$portdata"
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            local result=$(sudo ufw deny "$port")
            checkSuccess "Closing port $port for $app_name in the UFW Firewall"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            local result=$(sudo ufw-docker deny "$app_name" "$port")
            checkSuccess "Closing port $port for $$app_name in the UFW-Docker Firewall"
        fi
    else
        isNotice "Unable to find port in the database...skipping..."
    fi
}

unlogPort()
{
    local app_name="$1"
    local port="$2"

    databasePortRemove "$app_name" "$port"
}

removeAppPorts()
{
    local app_name="$1"

    # Open Ports
    # Check if open_initial_ports is not empty
    if [ -n "$open_initial_ports" ]; then
        # Split the configuration into an array using a comma as a delimiter
        IFS=',' read -ra openports <<< "$open_initial_ports"
        for i in "${!openports[@]}"; do
            local open_variable_name="openport$((i+1))"
            eval "$open_variable_name=${openports[i]}"
        done
    else
        isNotice "No data found for open port configuration."
    fi

    # Loop through the port variables and log each port
    for i in "${!openports[@]}"; do
        local open_variable_name="openport$((i+1))"
        local open_port_value="${!open_variable_name}"
        closePort "$app_name" "$open_port_value"
    done

    # Used Ports
    # Check if used_initial_ports is not empty
    if [ -n "$used_initial_ports" ]; then
        # Split the configuration into an array using a comma as a delimiter
        IFS=',' read -ra usedports <<< "$used_initial_ports"
        for i in "${!usedports[@]}"; do
            local used_variable_name="usedport$((i+1))"
            eval "$used_variable_name=${usedports[i]}"
        done
    else
        isNotice "No data found for used port configuration."
    fi

    # Loop through the port variables and log each port
    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        unlogPort "$app_name" "$used_port_value"
    done

    isNotice "All ports have been removed and closed (if required)."
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