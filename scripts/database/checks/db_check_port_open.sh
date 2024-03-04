#!/bin/bash

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
                        portOpenAddConflict "$app_name" "$port" "$type" "$app_name_from_db"
                        
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
