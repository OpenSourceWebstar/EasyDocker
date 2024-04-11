#!/bin/bash

appGetKeyData() 
{
    local app_name="$1"
    local file_path="$2"
    local key="$3"

    # Example of usage
    # password=$(get_password "your_app" "config_file.conf" "LD_SUPERUSER_PASSWORD")

    # Check if the file exists
    if [ -f "/docker/containers/$app_name/$file_path" ]; then
        # Extract the line containing the password key
        local password_line=$(grep "^$key=" "/docker/containers/$app_name/$file_path")

        # Extract the password value using cut or awk
        local password=$(echo "$password_line" | cut -d '=' -f 2)
    else
        isNotice "File $(basename "$basefile_path") not found for $app_name"
    fi
}
