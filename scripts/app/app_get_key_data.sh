#!/bin/bash

appGetKeyData() 
{
    local app_name="$1"
    local file_path="$2"
    local key="$3"

    # Check if the file exists
    if [ -f "$containers_dir$app_name/$file_path" ]; then
        # Extract the line containing the key
        local key_line=$(grep "^$key=" "$containers_dir$app_name/$file_path")

        # Extract the value using cut or awk
        local value=$(echo "$key_line" | cut -d '=' -f 2)
        echo "$value"
    else
        echo "File $file_path not found for $app_name" >&2
        return 1
    fi
}