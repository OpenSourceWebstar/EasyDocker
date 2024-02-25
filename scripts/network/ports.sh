#!/bin/bash

clearAllPortData()
{
    # Open Ports
    # Clean previous data (unset openport* variables)
    for varname in $(compgen -A variable | grep -E "^openport[0-9]+"); do
        unset "$varname"
    done
    unset openports open_ports open_initial_ports
    # Used Ports
    # Clean previous data (unset openport* variables)
    for varname in $(compgen -A variable | grep -E "^usedport[0-9]+"); do
        unset "$varname"
    done
    unset usedports used_ports_var used_initial_ports
}

########################
#       Add Ports      #
########################
checkAppPorts()
{
    local app_name="$1"
    local flag="$2"

    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        if [[ $used_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local used_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$used_port_value")
            usePort "$app_name" "$used_port_value" "$flag"
        fi
    done

    for i in "${!openports[@]}"; do
        local open_variable_name="openport$((i+1))"
        local open_port_value="${!open_variable_name}"
        if [[ $open_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local open_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$open_port_value")
            openPort "$app_name" "$open_port_value" "$flag"
        fi
    done

    removeStalePorts "$app_name";
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
            if [[ $disallow_open_port == "false" ]]; then
                databasePortOpenInsert "$app_name" "$portdata"
                if [[ $app_name == "standalonewireguard" ]]; then
                    local result=$(sudo ufw allow "$port/$type")
                    checkSuccess "Opening port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    local result=$(sudo ufw allow "$port/$type")
                    checkSuccess "Opening port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    local result=$(sudo ufw-docker allow "$app_name" "$port/$type")
                    checkSuccess "Opening port $port and type $type for $app_name in the UFW-Docker Firewall"
                fi
            fi
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
            if [[ $disallow_used_port == "false" ]]; then
                databasePortInsert "$app_name" "$port"
            fi
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
            # Convert to lowercase to avoid bad port issues
            local open_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$open_port_value")
            closePort "$app_name" "$open_port_value" remove
        fi
    done

    # Loop through the port variables and log each port
    for i in "${!usedports[@]}"; do
        local used_variable_name="usedport$((i+1))"
        local used_port_value="${!used_variable_name}"
        if [[ $used_port_value != "" ]]; then
            # Convert to lowercase to avoid bad port issues
            local used_port_value=$(tr '[:upper:]' '[:lower:]' <<< "$used_port_value")
            unusePort "$app_name" "$used_port_value" remove
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
        if portOpenExistsInDatabase "$app_name" "$port" "$type" "$flag"; then
            if [[ $disallow_open_port == "false" ]]; then
                databasePortOpenRemove "$app_name" "$portdata"
                if [[ $app_name == "standalonewireguard" ]]; then
                    local result=$(sudo ufw delete allow "$port/$type")
                    checkSuccess "Closing port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
                    local result=$(sudo ufw delete allow "$port/$type")
                    checkSuccess "Closing port $port and type $type for $app_name in the UFW Firewall"
                elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
                    local result=$(sudo ufw-docker delete allow "$app_name" "$port/$type")
                    checkSuccess "Closing port $port and type $type for $app_name in the UFW-Docker Firewall"
                fi
            fi
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
            if [[ $disallow_used_port == "false" ]]; then
                databasePortRemove "$app_name" "$port";
            fi
        fi
    fi
}

removeStalePorts()
{
    local app_name="$1"
    local db_used_ports=($(databaseGetUsedPortsForApp "$app_name"))
    local db_open_ports=($(databaseGetOpenPortsForApp "$app_name"))

    # Remove open ports that exist in the database but not in openports
    for db_open_port in "${db_open_ports[@]}"; do
        if ! containsElement "$db_open_port" "${openports[@]}"; then
            closePort "$app_name" "$db_open_port" stale
        fi
    done

    # Remove used ports that exist in the database but not in usedports
    for db_used_port in "${db_used_ports[@]}"; do
        if ! containsElement "$db_used_port" "${usedports[@]}"; then
            unusePort "$app_name" "$db_used_port" stale
        fi
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
    disallow_used_port=false

    if [[ $port != "" ]]; then
        if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
            local table_name=ports
            local app_name_from_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM $table_name WHERE port = '$port';")
            
            # If app_name_from_db is found
            if [[ ! -z "$app_name_from_db" ]]; then
                if [[ "$app_name" != "$app_name_from_db" ]]; then
                    isNotice "Unable to use port $port for application $app_name"
                    isNotice "Port $port is already used by $app_name_from_db."
                    isNotice "This WILL cause issues, please find a unique port for $app_name"
                    if [[ $flag == "install" ]] || [[ $flag == "remove" ]]; then
                        disallow_used_port=true
                    fi

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
                    if [[ $flag == "install" ]] || [[ $flag == "remove" ]]; then
                        disallow_used_port=true
                    fi
                    return 0  # Port exists in the database
                fi
            else
                if [[ $flag != "scan" ]]; then
                    isSuccessful "Used Port $port does not exist in the database...continuing..."
                fi
                return 1  # Port does not exist in the database
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
    disallow_open_port=false

    if [[ $port != "" ]]; then
        if [[ $type != "" ]]; then
            if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
                local table_name=ports_open
                local app_name_from_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM $table_name WHERE port = '$port' AND type = '$type';")
                
                # If app_name_from_db is found
                if [[ ! -z "$app_name_from_db" ]]; then
                    if [[ "$app_name" != "$app_name_from_db" ]]; then
                        isNotice "Unable to use port $port for application $app_name"
                        isNotice "Port $port and type $type is already open for $app_name_from_db."
                        isNotice "This WILL cause issues, please find a unique port for $app_name"
                        if [[ $flag == "install" ]] || [[ $flag == "remove" ]]; then
                            disallow_open_port=true
                        fi

                        # Conflict start
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
                        if [[ $flag == "install" ]] || [[ $flag == "remove" ]]; then
                            disallow_open_port=true
                        fi
                        return 0  # Port exists in the database
                    fi
                else
                    if [[ $flag != "scan" ]]; then
                        isSuccessful "Open Port $port does not exist in the database...continuing..."
                    fi
                    return 1  # Port does not exist in the database
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

    local db_used_ports=$(databaseGetUsedPorts "$app_name")
    local db_open_ports=$(databaseGetOpenPorts "$app_name")

    for db_used_port in $db_used_ports; do
        databaseRemoveUsedPort "$app_name" "$db_used_port"
    done

    for db_open_port in $db_open_ports; do
        local port_info=($(echo "$db_open_port" | tr '/' ' ')) # Split port/type info
        local port="${port_info[0]}"
        local type="${port_info[1]}"

        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            local result=$(sudo ufw delete allow "$port")
            checkSuccess "Closing port $port for $app_name in the UFW Firewall"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
            local result=$(sudo ufw-docker deny "$app_name" "$port")
            checkSuccess "Closing port $port for $app_name in the UFW-Docker Firewall"
        fi

        # Remove the open port entry from the database
        databaseGetOpenPort "$app_name" "$port" "$type"
    done
}
