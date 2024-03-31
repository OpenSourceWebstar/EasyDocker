#!/bin/bash

fixAppFolderPermissions() 
{
    local silent_flag="$1"

    # Collect all app names in an array
    local app_names=()
    for app_dir in "$containers_dir"/*/; do
        if [ -d "$app_dir" ]; then
            local app_name=$(basename "$app_dir")
            app_names+=("$app_name")
        fi
    done

    for app_name in "${app_names[@]}"; do
        if [[ $app_name != "" ]]; then
    
            # Updating $containers_dir with execute permissions
            if [ -d "$containers_dir" ]; then
                local result=$(sudo chmod +x "$containers_dir" > /dev/null 2>&1)
                if [ "$silent_flag" == "loud" ]; then
                    checkSuccess "Updating $containers_dir with execute permissions."
                fi
            else
                if [ "$silent_flag" == "loud" ]; then
                    isNotice "$containers_dir does not exist."
                fi
            fi

            # Updating $containers_dir$app_name with execute permissions
            if [ -d "$containers_dir$app_name" ]; then
                local result=$(sudo chmod +x "$containers_dir$app_name" > /dev/null 2>&1)
                if [ "$silent_flag" == "loud" ]; then
                    checkSuccess "Updating $containers_dir$app_name with execute permissions."
                fi
            else
                if [ "$silent_flag" == "loud" ]; then
                    isNotice "$containers_dir$app_name does not exist."
                fi
            fi

            # Updating $app_name with read permissions
            if [ -d "$containers_dir$app_name" ]; then
                local result=$(sudo chmod o+r "$containers_dir$app_name")
                if [ "$silent_flag" == "loud" ]; then
                    checkSuccess "Updating $app_name with read permissions"
                fi
            else
                if [ "$silent_flag" == "loud" ]; then
                    isNotice "$containers_dir$app_name does not exist."
                fi
            fi

            # Updating compose file(s) for EasyDocker access
            if [ -d "$containers_dir$app_name" ]; then
                local result=$(sudo find "$containers_dir$app_name" -type f -name '*docker-compose*' -exec chmod o+r {} \;)
                if [ "$silent_flag" == "loud" ]; then
                    isNotice "Updating compose file(s) for EasyDocker access"
                fi
            else
                if [ "$silent_flag" == "loud" ]; then
                    isNotice "$containers_dir$app_name does not exist."
                fi
            fi

            # Fix EasyDocker specific file permissions
            local files=("migrate.txt" "$app_name.config" "docker-compose.yml" "docker-compose.$app_name.yml")
            for file in "${files[@]}"; do
                local file_path="$containers_dir$app_name/$file"
                # Check if the file exists
                if [ -e "$file_path" ]; then
                    local result=$(sudo chown $docker_install_user:$docker_install_user "$file_path")
                    if [ "$silent_flag" == "loud" ]; then
                        checkSuccess "Updating $file with $docker_install_user ownership"
                    fi
                else
                    if [ "$silent_flag" == "loud" ]; then
                        isNotice "File $file does not exist in $app_name directory."
                    fi
                fi
            done
        fi
    done
}
