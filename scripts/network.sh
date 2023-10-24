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

            # Used Ports
            # Clean previous data (unset openport* variables)
            for varname in $(compgen -A variable | grep -E "^usedport[0-9]+"); do
                unset "$varname"
            done
            unset usedports used_ports_var used_initial_ports
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

            # Open Ports
            # Clean previous data (unset openport* variables)
            for varname in $(compgen -A variable | grep -E "^openport[0-9]+"); do
                unset "$varname"
            done
            unset openports used_ports_var used_initial_ports
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

########################
#       Add Ports      #
########################
checkAppPorts()
{
    local app_name="$1"
    local flag="$2"

    local db_used_ports=($(databaseGetUsedPortsForApp "$app_name"))
    local db_open_ports=($(databaseGetOpenPortsForApp "$app_name"))

    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        if [[ $used_port_value != "" ]]; then
            # Check if the port is in the ports table in the database
            if ! containsElement "$used_port_value" "${db_used_ports[@]}"; then
                usePort "$app_name" "$used_port_value" "$flag"
            fi
        fi
    done

    for i in "${!openports[@]}"; do
        local open_variable_name="openport$((i+1))"
        local open_port_value="${!open_variable_name}"
        if [[ $open_port_value != "" ]]; then
            # Check if the port is in the ports_open table in the database
            if ! containsElement "$open_port_value" "${db_open_ports[@]}"; then
                openPort "$app_name" "$open_port_value" "$flag"
            fi
        fi
    done

    #removeStalePorts "$app_name" "${db_used_ports[@]}" "${db_open_ports[@]}"
}

openPort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw
    local flag="$3"

    if [[ $portdata != "" ]]; then
        IFS='/' read -r port type <<< "$portdata"

        # Check if the port already exists in the database
        if ! portOpenExistsInDatabase "$app_name" "$port" "$type" "$flag"; then
            databasePortOpenInsert "$app_name" "$portdata"
        else
            return
        fi

        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            local result=$(sudo ufw allow "$port")
            checkSuccess "Opening port $port for $app_name in the UFW Firewall"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            local result=$(sudo ufw-docker allow "$app_name" "$port")
            checkSuccess "Opening port $port for $$app_name in the UFW-Docker Firewall"
        fi
    fi
}

usePort()
{
    local app_name="$1"
    local port="$2"
    local flag="$3"

    if [[ $port != "" ]]; then
        # Check if the port already exists in the database
        if ! portExistsInDatabase "$app_name" "$port" "$flag"; then
            databasePortInsert "$app_name" "$port"
        fi
    fi
}

########################
#     Remove Ports     #
########################
removeAppPorts()
{
    local app_name="$1"

    # Loop through the port variables and log each port
    for i in "${!openports[@]}"; do
        local open_variable_name="openport$((i+1))"
        local open_port_value="${!open_variable_name}"
        if [[ $open_port_value != "" ]]; then
            closePort "$app_name" "$open_port_value"
        fi
    done

    # Loop through the port variables and log each port
    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        if [[ $used_port_value != "" ]]; then
            unusePort "$app_name" "$used_port_value"
        fi
    done

    isNotice "All ports have been removed and closed (if required)."
}

closePort()
{
    local app_name="$1" # $app_name if ufw-docker, number if ufw
    local portdata="$2" # port/type if ufw-docker, empty if ufw
    local flag="$3"

    if [[ $portdata != "" ]]; then
        if [[ $flag == "stale" ]]; then
            isNotice "Old stale port $port found for $app_name and is now being closed."
        fi
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
            return
        fi
    fi
}

unusePort()
{
    local app_name="$1"
    local port="$2"
    local flag="$3"

    if [[ $port != "" ]]; then
        if [[ $flag == "stale" ]]; then
            isNotice "Old stale port $port found for $app_name and is being removed from the database."
        fi
        if portExistsInDatabase "$app_name" "$port" "$flag"; then
            databasePortRemove "$app_name" "$port";
        fi
    fi
}

removeStalePorts() 
{
    local app_name="$1"
    local used_ports=("${@:2}")
    local open_ports=("${@:3}")

    for open_port in "${open_ports[@]}"; do
        closePort "$app_name" "$open_port" stale
    done

    for used_port in "${used_ports[@]}"; do
        unusePort "$app_name" "$used_port" stale
    done
}

########################
#      Used Ports      #
########################
portExistsInDatabase()
{
    local app_name="$1"
    local port="$2"
    local flag="$3"

    if [[ $port != "" ]]; then
        if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
            local table_name=ports
            local app_name_from_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM $table_name WHERE port = '$port';")
            
            # If app_name_from_db is found
            if [[ ! -z "$app_name_from_db" ]]; then
                if [[ "$app_name" != "$app_name_from_db" ]]; then
                    isError "Unable to use port $port for application $app_name"
                    isError "Port $port is already used by $app_name_from_db."
                    isError "This WILL cause issues, please find a unique port for $app_name"

                    # Conflict start
                    addPortConflict "$app_name" "$port" "$app_name_from_db"

                    return 0  # Port exists in the database
                elif [[ "$app_name" == "$app_name_from_db" ]]; then
                    if [[ $flag != "scan" ]]; then
                        isNotice "Port $port is already setup for $app_name_from_db."
                    fi
                    return 0  # Port exists in the database
                elif [ -n "$app_name_from_db" ]; then
                    if [[ $flag != "scan" ]]; then
                        isNotice "Port $port is already used by $app_name_from_db."
                    fi
                    return 0  # Port exists in the database
                else
                    if [[ $flag != "scan" ]]; then
                        isSuccessful "No port found for $port...continuing..."
                    fi
                    return 1  # Port does not exist in the database
                fi
            else
                if [[ $flag != "scan" ]]; then
                    isSuccessful "No application found for port $port...continuing..."
                fi
                return 1  # No application found for the port, no conflict
            fi
        fi
    fi
}

addPortConflict() 
{
    local app_name="$1"
    local port="$2"
    local app_name_from_db="$3"

    portConflicts=()
    portConflicts+=("$app_name Port $port is already used by $app_name_from_db.")
}

portConflictFound() 
{
    local app_name="$1"

    if [ -n "$app_name" ]; then
        # Iterate through the array to find conflicts for the specific app_name
        for usedconflict in "${portConflicts[@]}"; do
            if [[ "$usedconflict" == *"$app_name"* ]]; then
                echo ""
                echo "##########################################"
                echo "######    Port Conflict(s) Found    ######"
                echo "##########################################"
                echo ""
                isNotice "Port conflicts have been found for $app_name:"
                echo ""
                local conflicts_without_app_name="${usedconflict/$app_name /}"  
                isError "$conflicts_without_app_name"

                while true; do
                    echo ""
                    isNotice "Please edit the ports in the configuration file for $app_name."
                    echo ""
                    isQuestion "Would you like to edit the config for $app_name? (y/n): "
                    read -p "" portconfigedit_choice
                    if [[ -n "$portconfigedit_choice" ]]; then
                        if [[ "$portconfigedit_choice" =~ [yY] ]]; then
                            editAppConfig "$app_name"
                        fi
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
            fi
        done
    fi
}

########################
#      Open Ports      #
########################
portOpenExistsInDatabase()
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    local flag="$4"

    if [[ $port != "" ]]; then
        if [[ $type != "" ]]; then
            if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
                local table_name=ports_open
                local app_name_from_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM $table_name WHERE port = '$port' AND type = '$type';")
                
                # If app_name_from_db is found
                if [[ ! -z "$app_name_from_db" ]]; then
                    if [[ "$app_name" != "$app_name_from_db" ]]; then
                        isError "Unable to use port $port for application $app_name"
                        isError "Port $port and type $type is already open for $app_name_from_db."
                        isError "This WILL cause issues, please find a unique port for $app_name"
                        
                        # Conflict start
                        declare -a openPortConflicts
                        addOpenPortConflict "$app_name" "$port" "$type" "$app_name_from_db"
                        
                        return 0  # Port exists in the database
                    elif [[ "$app_name" == "$app_name_from_db" ]]; then
                        if [[ $flag != "scan" ]]; then
                            isNotice "Port $port is already open and setup for $app_name_from_db."
                        fi
                        return 0  # Port exists in the database
                    elif [ -n "$app_name_from_db" ]; then
                        if [[ $flag != "scan" ]]; then
                            isNotice "Port $port is already open and used by $app_name_from_db."
                        fi
                        return 0  # Port exists in the database
                    else
                        if [[ $flag != "scan" ]]; then
                            isSuccessful "No open port found for $port...continuing..."
                        fi
                        return 1  # Port does not exist in the database
                    fi
                else
                    if [[ $flag != "scan" ]]; then
                        isSuccessful "No application found for port $port...continuing..."
                    fi
                    return 1  # No application found for the port, no conflict
                fi
            fi
        fi
    fi
}

addOpenPortConflict() 
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    local app_name_from_db="$4"
    
    if [ -n "$app_name" ] && [ -n "$port" ] && [ -n "$type" ] && [ -n "$app_name_from_db" ]; then
        openPortConflicts=()
        openPortConflicts+=("Port $port and type $type are already open and used by $app_name_from_db for $app_name.")
    fi
}

openPortConflictFound() 
{
    local app_name="$1"

    if [ -n "$app_name" ]; then
        # Iterate through the array to find conflicts for the specific app_name
        for openconflict in "${openPortConflicts[@]}"; do
            if [[ "$openconflict" == *"$app_name"* ]]; then
                echo ""
                echo "###############################################"
                echo "######    Open Port Conflict(s) Found    ######"
                echo "###############################################"
                echo ""
                isNotice "Open port conflicts have been found for $app_name:"
                echo ""
                local conflicts_without_app_name="${openconflict/$app_name /}"  
                isError "$conflicts_without_app_name"

                while true; do
                    echo ""
                    isNotice "Please edit the ports in the configuration file for $app_name."
                    echo ""
                    isQuestion "Would you like to edit the config for $app_name? (y/n): "
                    read -p "" openportconfigedit_choice
                    if [[ -n "$openportconfigedit_choice" ]]; then
                        if [[ "$openportconfigedit_choice" =~ [yY] ]]; then
                            editAppConfig "$app_name"
                        fi
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
            fi
        done
    fi
}

########################
#   Conflict Handler   #
########################
handleAllConflicts() 
{
    for usedconflict in "${portConflicts[@]}"; do
        local app_name=$(echo "$usedconflict" | awk '{print $1}')
        portConflictFound "$app_name"
    done

    for openconflict in "${openPortConflicts[@]}"; do
        local app_name=$(echo "$openconflict" | awk '{print $1}')
        openPortConflictFound "$app_name"
    done
}

########################
#      Clear Ports     #
########################
removePortsFromDatabase()
{
    local app_name="$1"

    local used_ports=$(databaseGetUsedPorts "$app_name")

    for used_port in $used_ports; do
        databaseRemoveUsedPort "$app_name" "$used_port"
    done

    local open_ports=$(databaseGetOpenPorts "$app_name")

    for open_port in $open_ports; do
        local port_info=($(echo "$open_port" | tr '/' ' ')) # Split port/type info
        local port="${port_info[0]}"
        local type="${port_info[1]}"

        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            local result=$(sudo ufw deny "$port")
            checkSuccess "Closing port $port for $app_name in the UFW Firewall"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            local result=$(sudo ufw-docker deny "$app_name" "$port")
            checkSuccess "Closing port $port for $app_name in the UFW-Docker Firewall"
        fi

        # Remove the open port entry from the database
        databaseGetOpenPort "$app_name" "$port" "$type"
    done
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