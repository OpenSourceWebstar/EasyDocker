#!/bin/bash

sourceScanFiles() 
{
    local load_type="$1"
    local file_pattern

    # Specific EasyDocker config files
    if [ "$load_type" = "easydocker_configs" ]; then
        local file_pattern="config_*"
        local folder_dir="$configs_dir"

    # Specific for EasyDocker app container configs
    elif [ "$load_type" = "app_configs" ]; then
        local file_pattern="*.config"
        local folder_dir="$containers_dir"

    # Specific for EasyDocker app install scripts
    elif [ "$load_type" = "containers" ]; then
        local file_pattern="*.sh"
        local folder_dir="$install_containers_dir"
    else
        echo "Invalid load type: $load_type"
        return
    fi

    # Scanning function
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$file"
            # echo "$load_type FILE $file"
        fi
    done < <(sudo find "$folder_dir" -maxdepth 3 -type d \( -name 'resources' \) -prune -o -type f -name "$file_pattern" -print0)

    # Load the categories from the file into an array
    if [ "$load_type" = "easydocker_configs" ]; then
        mapfile -t app_categories < $configs_dir/app_categories
    fi
}
