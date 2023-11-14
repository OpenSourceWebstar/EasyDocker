#!/bin/bash

runStart()
{  
    local path="$3"
    cd $script_dir
    local result=$(sudo chmod 0755 start.sh)
    checkSuccess "Updating Start Script Permissions"
    
    local result=$(sudo ./start.sh "" "" "$path")
    checkSuccess "Running Start script"
}

runInit()
{
    cd $script_dir
    local result=$(sudo chmod 0755 init.sh)
    checkSuccess "Updating Init Script Permissions"
    
    local result=$(sudo ./init.sh run)
    checkSuccess "Running Init Script"
}

runUpdate()
{
    cd $script_dir
    local result=$(sudo chmod 0755 update.sh)
    checkSuccess "Updating Update Script Permissions"
    
    local result=$(sudo ./update.sh)
    checkSuccess "Running Update Script"
}

fixConfigPermissions()
{
    local silent_flag="$1"
    local app_name="$2"
    local config_file="$containers_dir$app_name/$app_name.config"

    local result=$(sudo chmod g+rw $config_file)
    if [ "$silent_flag" == "loud" ]; then
        isNotice "Updating config read permissions for EasyDocker"
    fi

    fixFolderPermissions $app_name;
}

fixFolderPermissions()
{
    local app_name="$1"

	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        # EasyDocker
        local result=$(echo -e "$CFG_DOCKER_INSTALL_PASS\n$CFG_DOCKER_INSTALL_PASS" | sudo passwd "$CFG_DOCKER_INSTALL_USER" > /dev/null 2>&1)
        checkSuccess "Updating the password for the $CFG_DOCKER_INSTALL_USER user"

        local result=$(sudo chmod +x "$docker_dir" > /dev/null 2>&1)
        checkSuccess "Updating $docker_dir with execute permissions."

        local result=$(sudo find "$script_dir" "$ssl_dir" "$ssh_dir" "$backup_dir" "$restore_dir" "$migrate_dir" -maxdepth 2 -type d -exec sudo chmod +x {} \;)
        checkSuccess "Adding execute permissions for $CFG_DOCKER_INSTALL_USER user"

        # Install user related
        local result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$containers_dir" > /dev/null 2>&1)
        checkSuccess "Updating $containers_dir with $CFG_DOCKER_INSTALL_USER ownership"

        # Update permissions after
        #local result=$(sudo find "$containers_dir" -maxdepth 2 -type d -exec sudo setfacl -R -m u:$sudo_user_name:rwX {} \; > /dev/null 2>&1)
        #checkSuccess "Updating $containers_dir with $sudo_user_name read permissions" 
    fi
}

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
                    local result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$file_path")
                    if [ "$silent_flag" == "loud" ]; then
                        checkSuccess "Updating $file with $CFG_DOCKER_INSTALL_USER ownership"
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


fixPermissionsBeforeStart()
{
    local app_name="$1"
    local flag="$2"
    
    if [[ $flag == "update" ]]; then
        echo ""
        echo "##########################################"
        echo "###  Updating File/Folder Permissions  ###"
        echo "##########################################"
        echo ""
    fi

    fixAppFolderPermissions;

	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        # Mainly for "full"
        changeRootOwnedFilesAndFolders $script_dir $CFG_DOCKER_INSTALL_USER
        changeRootOwnedFile $docker_dir/$db_file $sudo_user_name
    fi

    # App Specific
    if [[ $app_name != "" ]]; then
        changeRootOwnedFilesAndFolders $containers_dir$app_name $CFG_DOCKER_INSTALL_USER
    fi

    # Traefik
    if [ -f "${containers_dir}traefik/etc/certs/acme.json" ]; then
        updateFileOwnership "${containers_dir}traefik/etc/certs/acme.json" $CFG_DOCKER_INSTALL_USER
        local result=$(sudo chmod 600 "${containers_dir}traefik/etc/certs/acme.json")
        checkSuccess "Set permissions to acme.json file for traefik"
    fi
    if [ -f "${containers_dir}traefik/etc/traefik.yml" ]; then
        updateFileOwnership "${containers_dir}traefik/etc/traefik.yml" $CFG_DOCKER_INSTALL_USER
        local result=$(sudo chmod 600 "${containers_dir}traefik/etc/traefik.yml")
        checkSuccess "Set permissions to traefik.yml file for traefik"
    fi
}

changeRootOwnedFilesAndFolders()
{
    local dir_to_change="$1"
    local user_name="$2"

    # Check if the directory exists
    if [ ! -d "$dir_to_change" ]; then
        isError "Install directory '$dir_to_change' does not exist."
        return 1
    fi

    # Start the result command in the background
    (sudo find "$dir_to_change" -type f -user root -exec sudo chown "$user_name:$user_name" {} \; ) &

    local start_time=$(date +%s)
    local time_threshold=5

    # Check periodically if the result command is still running
    while ps -p $! > /dev/null; do
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "$time_threshold" ]; then
            # Display the message
            isNotice "Updating ownership of $dir_to_change...this may take a while depending on the size/amount of files..."
            break
        fi
        sleep 1
    done
    isSuccessful "Find files owned by root and change ownership"

    local result=$(sudo find "$dir_to_change" -type d -user root -exec sudo chown "$user_name:$user_name" {} \;)
    checkSuccess "Find directories owned by root and change ownership"

    isSuccessful "Updated ownership of root-owned files and directories."
}

changeRootOwnedFile()
{
    local file_full="$1" # Includes path
    local file_name=$(basename "$file")
    local user_name="$2"

    # Check if the file exists
    if [ ! -f "$file_full" ]; then
        if [[ $file_full == "$docker_dir/$db_file" ]]; then
            isNotice "$db_file is not yet created."
        else
            isError "File '$file_full' does not exist."
        fi
        return 1
    fi

    local result=$(sudo sudo chown "$user_name:$user_name" "$file_full")
    checkSuccess "Updating $file_name to be owned by $user_name"
}

mkdirFolders()
{
    local silent_flag="$1"
    local user_name="$2"

    for dir_path in "${@:3}"; do
        local folder_name=$(basename "$dir_path")
        local clean_dir=$(echo "$dir_path" | sed 's#//*#/#g')

        local result=$(sudo mkdir -p "$dir_path")
        if [ -z "$silent_flag" ]; then
            checkSuccess "Creating $folder_name directory"
        fi

        local result=$(sudo chown $user_name:$user_name "$dir_path")
        if [ "$silent_flag" == "silent" ]; then
            checkSuccess "Updating $folder_name with $user_name ownership"
        fi
    done
}


backupContainerFilesToTemp()
{
    local app_name="$1"
    local source_folder="$containers_dir$app_name"

    temp_backup_folder="temp_$(date +%Y%m%d%H%M%S)_$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 6)"

    local result=$(mkdirFolders "loud" $sudo_user_name "$temp_backup_folder")
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
        target_file="$source_file"
        if [ -f "$source_file" ]; then
            moveFile "$source_file" "$target_file"
            checkSuccess "Moving $source_filename to $temp_backup_folder"
        fi
    done
}

backupContainerFilesRestore()
{
    local app_name="$1"
    local source_folder="$containers_dir$app_name"

    if [ -d "$temp_backup_folder" ]; then
        local result=$(copyFiles "loud" "$temp_backup_folder" "$source_folder" $CFG_DOCKER_INSTALL_USER)
        checkSuccess "Copying files from temp folder to $app_name folder."
        local result=$(rm -rf "$temp_backup_folder")
        checkSuccess "Removing temp folder as no longer needed."
    fi
}

copyFolder()
{
    local folder="$1"
    local folder_name=$(basename "$folder")
    local save_dir="$2"
    local user_name="$3"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    local result=$(sudo cp -rf "$folder" "$save_dir")
    checkSuccess "Coping $folder_name to $save_dir"

    local result=$(sudo chown $user_name:$user_name "$save_dir/$folder_name")
    checkSuccess "Updating $folder_name with $user_name ownership"
}

copyFolders()
{
    local source="$1"
    local save_dir="$2"
    local user_name="$3"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    # Ensure the source path is expanded to a list of subdirectories
    local subdirs=($(find "$source" -mindepth 1 -maxdepth 1 -type d))

    if [ ${#subdirs[@]} -eq 0 ]; then
        echo "No subdirectories found in the source directory: $source"
        return
    fi

    for subdir in "${subdirs[@]}"; do
        local subdir_name=$(basename "$subdir")

        local result=$(sudo cp -rf "$subdir" "$save_dir")
        checkSuccess "Copying $subdir_name to $save_dir"

        local result=$(sudo chown -R $user_name:$user_name "$save_dir/$subdir_name")
        checkSuccess "Updating $subdir_name with $user_name ownership"
    done
}

copyResource()
{
    local app_name="$1"
    local file_name="$2"
    local save_path="$3"

    local app_dir=$install_containers_dir$app_name

    # Check if the app_name folder was found
    if [ -z "$app_dir" ]; then
        echo "App folder '$app_name' not found in '$install_containers_dir'."
    fi

    local result=$(sudo cp "$app_dir/resources/$file_name" "$containers_dir/$app_name/$save_path")
    checkSuccess "Copying $file_name to $containers_dir/$app_name/$save_path"

    local result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$containers_dir/$app_name/$save_path/$file_name")
    checkSuccess "Updating $file_name with $CFG_DOCKER_INSTALL_USER ownership"
}

copyFile()
{
    local silent_flag="$1"
    local file="$2"
    local file_name=$(basename "$file")
    local save_dir="$3"
    local save_dir_file=$(basename "$save_dir")
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')
    local user_name="$4" 
    local flags="$5"

    if [[ $flags == "overwrite" ]]; then
        flags_full="-f"
    fi
    
    if [ "$silent_flag" == "loud" ]; then
        local result=$(sudo cp $flags_full "$file" "$save_dir")
        checkSuccess "Copying $file_name to $save_dir"
    elif [ "$silent_flag" == "silent" ]; then
        local result=$(sudo cp $flags_full "$file" "$save_dir")
    fi

    if [ "$silent_flag" == "loud" ]; then
        local result=$(sudo chown $user_name:$user_name "$save_dir")
        checkSuccess "Updating $save_dir_file with $user_name ownership"
    elif [ "$silent_flag" == "silent" ]; then
        local result=$(sudo chown $user_name:$user_name "$save_dir")
    fi
}

copyFiles()
{
    local silent_flag="$1"
    local source="$2"
    local save_dir="$3"
    local user_name="$4"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    # Ensure the source path is expanded to a list of files
    local files=($(sudo find "$source" -type f))

    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found in the source directory: $source"
        return
    fi

    for file in "${files[@]}"; do
        local file_name=$(basename "$file")

        if [ "$silent_flag" == "loud" ]; then
            local result=$(sudo cp -f "$file" "$save_dir")
            checkSuccess "Copying $file_name to $save_dir"
        elif [ "$silent_flag" == "silent" ]; then
            local result=$(sudo cp -f "$file" "$save_dir")
        fi

        if [ "$silent_flag" == "loud" ]; then
            local result=$(sudo chown $user_name:$user_name "$save_dir/$file_name")
            checkSuccess "Updating $file_name with $user_name ownership"
        elif [ "$silent_flag" == "silent" ]; then
            local result=$(sudo chown $user_name:$user_name "$save_dir/$file_name")
        fi
    done
}

createTouch() 
{
    local file="$1"
    local user_name="$2"
    local file_name=$(basename "$file")
    local file_dir=$(dirname "$file")
    local clean_dir=$(echo "$file" | sed 's#//*#/#g')

    local result=$(sudo touch "$clean_dir")
    checkSuccess "Touching $file_name to $file_dir"

    local result=$(sudo chown $user_name:$user_name "$file")
    checkSuccess "Updating $file_name with $user_name ownership"
}

updateFileOwnership() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local clean_dir=$(echo "$file" | sed 's#//*#/#g')
    local user_name="$2"

    local result=$(sudo chown $user_name:$user_name "$file")
    checkSuccess "Updating $file_name with $user_name ownership"
}

zipFile() 
{
    local passphrase="$1"
    local zip_file="$2"
    local zip_directory="$3"

    # Run the SSH command using the existing SSH variables
    local result=$(sudo zip -r -MM -e -P $passphrase $zip_file $zip_directory)
    checkSuccess "Zipped up $(basename "$zip_file")"

    local result=$(sudo chown $sudo_user_name:$sudo_user_name "$zip_file")
    checkSuccess "Updating $(basename "$zip_file") with $sudo_user_name ownership"
}

moveFile() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local save_dir="$2"
    local save_dir_file=$(basename "$save_dir")
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    if [ -e "$file" ]; then
        local result=$(sudo mv "$file" "$save_dir")
        checkSuccess "Moving $file_name to $save_dir"

        if [[ $clean_dir != *"$containers_dir"* ]]; then
            local result=$(sudo chown $sudo_user_name:$sudo_user_name "$save_dir")
            checkSuccess "Updating $save_dir_file with $sudo_user_name ownership"
        fi
    else
        isNotice "Source file does not exist: $file"
    fi
}
