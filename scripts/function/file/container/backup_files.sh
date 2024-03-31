#!/bin/bash

backupContainerFilesToTemp()
{
    local app_name="$1"
    local source_folder="$containers_dir$app_name"

    temp_backup_folder="temp_$(date +%Y%m%d%H%M%S)_$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 6)"

    local result=$(createFolders "loud" $docker_install_user "$temp_backup_folder")
    checkSuccess "Creating temp folder for backing up purposes."

    if [[ $compose_setup == "default" ]]; then
        local compose_file="docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local compose_file="docker-compose.$app_name.yml"
    fi

    local source_filenames=("$app_name.config" "migrate.txt" "$compose_file" ".env")
    # Iterate over the list and call moveFile for each source file
    for source_filename in "${source_filenames[@]}"; do
        source_file="$source_folder/$source_filename"
        target_file="$temp_backup_folder/$source_filename"
        if [ -f "$source_file" ]; then
            moveFile "$source_file" "$target_file"
            checkSuccess "Moving $source_filename to $temp_backup_folder"
        fi
    done
}
