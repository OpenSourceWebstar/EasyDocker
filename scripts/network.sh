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
                if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
                    #if [[ $app_name != *"virtualmin"* ]]; then
                        local result=$(sudo ufw allow "$port/$type")
                        checkSuccess "Opening port $port and type $type for $app_name in the UFW Firewall"
                    #else
                        #local result=$(sudo ufw allow from $ip_setup to any port "$port")
                        #checkSuccess "Opening port $port from $ip_setup for $app_name in the UFW Firewall"
                    #fi
                elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
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
                if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
                    #if [[ $app_name != *"virtualmin"* ]]; then
                        local result=$(sudo ufw delete allow "$port/$type")
                        checkSuccess "Closing port $port and type $type for $app_name in the UFW Firewall"
                    #else
                        #local result=$(sudo ufw delete allow from $ip_setup to any port "$port")
                        #checkSuccess "Closing port $port from $ip_setup for $app_name in the UFW Firewall"
                    #fi
                elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
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

        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            #if [[ $app_name != *"virtualmin"* ]]; then
                local result=$(sudo ufw delete allow "$port")
                checkSuccess "Closing port $port for $app_name in the UFW Firewall"
            #else
                #local result=$(sudo ufw delete from $ip_setup to any port "$port")
                #checkSuccess "Closing port $port for $app_name in the UFW Firewall"
            #fi
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            local result=$(sudo ufw-docker deny "$app_name" "$port")
            checkSuccess "Closing port $port for $app_name in the UFW-Docker Firewall"
        fi

        # Remove the open port entry from the database
        databaseGetOpenPort "$app_name" "$port" "$type"
    done
}

########################
#          DNS         #
########################
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

updateDNS() 
{
    local app_name="$1"
    local flag="$2"

	if [[ "$OS" == [1234567] ]]; then
        # Remove all existing nameserver lines
        result=$(sudo sed -i '/^nameserver/d' /etc/resolv.conf)
        checkSuccess "Removing all instances of Nameserver from Resolv.conf"

        # Check if AdGuard is installed
        local status=$(checkAppInstalled "adguard" "docker")
        if [ "$status" == "installed" ]; then
            setupDNSIP adguard;
            local adguard_ip="$dns_ip_setup"
            # Testing Docker IP Address
            result=$(sudo ping -c 3 $adguard_ip)
            if [ $? -eq 0 ]; then
                isSuccessful "Ping to $adguard_ip was successful."
            else
                isNotice "Ping to $adguard_ip failed."
                isNotice "Defaulting to DNS 1 Server $CFG_DNS_SERVER_1."
                local adguard_ip="$CFG_DNS_SERVER_1"
                # Fallback to Quad9 if DNS has issues
                result=$(sudo ping -c 3 $adguard_ip)
                if [ $? -eq 0 ]; then
                    isSuccessful "Ping to $adguard_ip was successful."
                else
                    isNotice "Ping to $adguard_ip failed."
                    isNotice "Defaulting to Quad 9 - 9.9.9.9"
                    local adguard_ip="9.9.9.9"
                fi
            fi
        else
            local adguard_ip="$CFG_DNS_SERVER_1"
            # Fallback to Quad9 if DNS has issues
            result=$(sudo ping -c 3 $adguard_ip)
            if [ $? -eq 0 ]; then
                isSuccessful "Ping to $adguard_ip was successful."
            else
                isNotice "Ping to $adguard_ip failed."
                isNotice "Defaulting to Quad 9 - 9.9.9.9"
                local adguard_ip="9.9.9.9"
            fi
        fi

        # Check if Pi-hole is installed
        local status=$(checkAppInstalled "pihole" "docker")
        if [ "$status" == "installed" ]; then
            setupDNSIP pihole;
            local pihole_ip="$dns_ip_setup"
            # Testing Docker IP Address
            result=$(sudo ping -c 3 $pihole_ip)
            if [ $? -eq 0 ]; then
                isSuccessful "Ping to $pihole_ip was successful."
            else
                isNotice "Ping to $pihole_ip failed."
                isNotice "Defaulting to DNS 2 Server $CFG_DNS_SERVER_2."
                local pihole_ip="$CFG_DNS_SERVER_2"
                # Fallback to Quad9 if DNS has issues
                result=$(sudo ping -c 3 $pihole_ip)
                if [ $? -eq 0 ]; then
                    isSuccessful "Ping to $pihole_ip was successful."
                else
                    isNotice "Ping to $pihole_ip failed."
                    isNotice "Defaulting to Quad 9 - 9.9.9.11"
                    local pihole_ip="9.9.9.11"
                fi
            fi
        else
            local pihole_ip="$CFG_DNS_SERVER_2"
            if [ $? -eq 0 ]; then
                isSuccessful "Ping to $pihole_ip was successful."
            else
                isNotice "Ping to $pihole_ip failed."
                isNotice "Defaulting to Quad 9 - 9.9.9.11"
                local pihole_ip="9.9.9.11"
            fi
        fi

        # Add the custom DNS servers to /etc/resolv.conf
        if [[ "$adguard_ip" == *10.8.1* ]]; then
            # Wireguard update
            local status=$(checkAppInstalled "wireguard" "docker")
            if [ "$status" == "installed" ]; then
                setupInstallVariables wireguard;
                if [[ $compose_setup == "default" ]]; then
                    local compose_file="docker-compose.yml"
                elif [[ $compose_setup == "app" ]]; then
                    local compose_file="docker-compose.$app_name.yml"
                fi
                result=$(sudo sed -i "s/\(WG_DEFAULT_DNS=\).*/\1$adguard_ip/" $containers_dir$app_name/$compose_file)
                checkSuccess "Updated Wireguard default DNS to $adguard_ip"
            fi
            echo "nameserver $adguard_ip" | sudo tee -a /etc/resolv.conf
            echo "nameserver $pihole_ip" | sudo tee -a /etc/resolv.conf
        elif [[ "$pihole_ip" == *10.8.1* ]]; then
            # Wireguard update
            local status=$(checkAppInstalled "wireguard" "docker")
            if [ "$status" == "installed" ]; then
                setupInstallVariables $app_name;
                if [[ $compose_setup == "default" ]]; then
                    local compose_file="docker-compose.yml"
                elif [[ $compose_setup == "app" ]]; then
                    local compose_file="docker-compose.$app_name.yml"
                fi
                result=$(sudo sed -i "s/\(WG_DEFAULT_DNS=\).*/\1$pihole_ip/" $containers_dir$app_name/$compose_file)
                checkSuccess "Updated Wireguard default DNS to $pihole_ip"
            fi
            echo "nameserver $pihole_ip" | sudo tee -a /etc/resolv.conf
            echo "nameserver $adguard_ip" | sudo tee -a /etc/resolv.conf
        else
            # Wireguard update
            local status=$(checkAppInstalled "wireguard" "docker")
            if [ "$status" == "installed" ]; then
                setupInstallVariables wireguard;
                if [[ $compose_setup == "default" ]]; then
                    local compose_file="docker-compose.yml"
                elif [[ $compose_setup == "app" ]]; then
                    local compose_file="docker-compose.$app_name.yml"
                fi
                result=$(sudo sed -i "s/\(WG_DEFAULT_DNS=\).*/\1$adguard_ip/" $containers_dir$app_name/$compose_file)
                checkSuccess "Updated Wireguard default DNS to $adguard_ip"
            fi
            echo "nameserver $adguard_ip" | sudo tee -a /etc/resolv.conf
            echo "nameserver $pihole_ip" | sudo tee -a /etc/resolv.conf
        fi
        if [ "$flag" == "install" ]; then
            setupInstallVariables $app_name;
        fi
        isSuccessful "Resolv.conf has been updated with the latest DNS settings."
    fi
}

firewallCommands()
{

    # Allow specific port through the firewall
    if [[ "$firewallallowport" == [yY] ]]; then
        echo ""
        echo "---- Allow specific port through the firewall :"
        echo ""
        while true; do
            isQuestion "Please enter the port you would like to open (enter 'x' to exit): "
            read -p "" firewallallowport_port
            if [[ "$firewallallowport_port" == [xX] ]]; then
                isNotice "Exiting..."
                break
            fi
            if [[ "$firewallallowport_port" =~ ^[0-9]+$ && $firewallallowport_port -ge 1 && $firewallallowport_port -le 65535 ]]; then
                local result=$(sudo ufw allow "$firewallallowport_port")
                checkSuccess "Opening port $firewallallowport_port in the UFW Firewall"
                break
            fi
            isNotice "Please provide a valid port number between 1 and 65535 or enter 'x' to exit."
        done
    fi

    # Block specific port through the firewall
    if [[ "$firewallblockport" == [yY] ]]; then
        echo ""
        echo "---- Block specific port through the firewall :"
        echo ""
        while true; do
            isQuestion "Please enter the port you would like to block (enter 'x' to exit): "
            read -p "" firewallblockport_port
            if [[ "$firewallblockport_port" == [xX] ]]; then
                isNotice "Exiting..."
                break
            fi
            if [[ "$firewallblockport_port" =~ ^[0-9]+$ && $firewallblockport_port -ge 1 && $firewallblockport_port -le 65535 ]]; then
                local result=$(sudo ufw deny "$firewallblockport_port")
                checkSuccess "Blocking port $firewallblockport_port in the UFW Firewall"
                break
            fi
            isNotice "Please provide a valid port number between 1 and 65535 or enter 'x' to exit."
        done
    fi

    # Block port 22 (SSH)
    if [[ "$firewallblock22" == [yY] ]]; then
        echo ""
        echo "---- Block port 22 (SSH) :"
        echo ""
        local result=$(sudo ufw deny 22)
        checkSuccess "Disabling Port 22 through the firewall"
        local result=$(sudo ufw deny ssh)
        checkSuccess "Disabling SSH through the firewall"
    fi

    # Allow port 22 (SSH)
    if [[ "$firewallallow22" == [yY] ]]; then
        echo ""
        echo "---- Allow port 22 (SSH) :"
        echo ""
        local result=$(sudo ufw allow 22)
        checkSuccess "Allowing Port 22 through the firewall"
        local result=$(sudo ufw allow ssh)
        checkSuccess "Allowing SSH through the firewall"
    fi

    # Update logging type for UFW based on Config
    if [[ "$firewallchangelogging" == [yY] ]]; then
        echo ""
        echo "---- Update logging type for UFW based on Config :"
        echo ""
        # Check if CFG_UFW_LOGGING is a valid UFW logging type
        case "$CFG_UFW_LOGGING" in
            on|off|low|medium|high|full)
                # Valid logging type
                local result=$(yes | sudo ufw logging $CFG_UFW_LOGGING)
                checkSuccess "Updating UFW Firewall Logging to $CFG_UFW_LOGGING"
                ;;
            *)
                # Invalid logging type
                isError "Invalid UFW logging type. Please set CFG_UFW_LOGGING to on, off, low, medium, high, or full."
                ;;
        esac
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