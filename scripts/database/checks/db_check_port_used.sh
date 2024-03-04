#!/bin/bash

########################
#      Used Ports      #
########################
portUsedExistsInDatabase()
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
                    portUsedAddConflict "$app_name" "$port" "$app_name_from_db"

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
