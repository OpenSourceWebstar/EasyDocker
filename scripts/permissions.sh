#!/bin/bash

runStart() 
{  
    local path="$3"
    cd $script_dir
    result=$(sudo chmod 0755 start.sh)
    checkSuccess "Updating Start Script Permissions"
    
    result=$(sudo ./start.sh "" "" "$path")
    checkSuccess "Running Start script"
}

runInit() 
{
    cd $script_dir
    result=$(sudo chmod 0755 init.sh)
    checkSuccess "Updating Init Script Permissions"
    
    result=$(sudo ./init.sh run)
    checkSuccess "Running Init Script"
}

runUpdate() 
{
    cd $script_dir
    result=$(sudo chmod 0755 update.sh)
    checkSuccess "Updating Update Script Permissions"
    
    result=$(sudo ./update.sh)
    checkSuccess "Running Update Script"
}

fixFolderPermissions() 
{
	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        # Docker install user setup
        result=$(echo -e "$CFG_DOCKER_INSTALL_PASS\n$CFG_DOCKER_INSTALL_PASS" | sudo passwd "$CFG_DOCKER_INSTALL_USER" > /dev/null 2>&1)
        checkSuccess "Updating the password for the $CFG_DOCKER_INSTALL_USER user"

        result=$(sudo chmod +x $base_dir $install_dir)
        checkSuccess "Adding execute permissions for $CFG_DOCKER_INSTALL_USER user"

        result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$install_dir")
        checkSuccess "Updating $install_dir with $CFG_DOCKER_INSTALL_USER ownership"

        # Easydocker user permissions
        result=$(sudo setfacl -R -m u:$sudo_user_name:rwX "$install_dir")
        checkSuccess "Updating $install_dir with $sudo_user_name read permissions"
    fi
}

fixPermissionsBeforeStart()
{
    local app_name="$1"

	if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        # Mainly for "full"
        changeRootOwnedFilesAndFolders $script_dir $CFG_DOCKER_INSTALL_USER
        changeRootOwnedFile $base_dir/$db_file $sudo_user_name
    fi

    # This is where custom app specific permissions are needed
    if [[ $app_name == "traefik" ]]; then
        updateFileOwnership "$install_dir$app_name/etc/certs/acme.json" $CFG_DOCKER_INSTALL_USER
        updateFileOwnership "$install_dir$app_name/etc/traefik.yml" $CFG_DOCKER_INSTALL_USER
        result=$(sudo chmod 600 "$install_dir$app_name/etc/certs/acme.json")
        checkSuccess "Set permissions to acme.json file for $app_name"
        result=$(sudo chmod 600 "$install_dir$app_name/etc/traefik.yml")
        checkSuccess "Set permissions to traefik.yml file for $app_name"
    fi
}

changeRootOwnedFilesAndFolders() 
{
    local install_dir="$1"
    local user_name="$2"

    # Check if the install directory exists
    if [ ! -d "$install_dir" ]; then
        isError "Install directory '$install_dir' does not exist."
        return 1
    fi

    isNotice "Updating ownership of $install_dir...this may take a while depending on the size/amount of files..."

    result=$(sudo find "$install_dir" -type f -user root -exec sudo chown "$user_name:$user_name" {} \;)
    checkSuccess "Find files owned by root and change ownership"

    result=$(sudo find "$install_dir" -type d -user root -exec sudo chown "$user_name:$user_name" {} \;)
    checkSuccess "Find directories owned by root and change ownership"

    isSuccessful "Ownership of root-owned files and directories in '$install_dir' has been changed to '$user_name'."
}

changeRootOwnedFile()
{
    local file_full="$1" # Includes path
    local file_name=$(basename "$file")
    local user_name="$2"

    # Check if the file exists
    if [ ! -f "$file_full" ]; then
        isError "File '$file_full' does not exist."
        return 1
    fi

    result=$(sudo sudo chown "$user_name:$user_name" "$file_full")
    checkSuccess "Updating $file_name to be owned by $user_name"
}

mkdirFolders() 
{
    for dir_path in "$@"; do
        local folder_name=$(basename "$dir_path")
        local clean_dir=$(echo "$dir_path" | sed 's#//*#/#g')

        result=$(sudo mkdir -p "$dir_path")
        checkSuccess "Creating $folder_name directory"
        if [[ $clean_dir == *"$install_dir"* ]]; then
            result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$dir_path")
            checkSuccess "Updating $folder_name with $CFG_DOCKER_INSTALL_USER ownership"
        else
            result=$(sudo chown $easydockeruser:$easydockeruser "$dir_path")
            checkSuccess "Updating $folder_name with $easydockeruser ownership"
        fi
    done
}

copyFolder() 
{
    local folder="$1"
    local folder_name=$(basename "$folder")
    local save_dir="$2"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    result=$(sudo cp -rf "$folder" "$save_dir")
    checkSuccess "Coping $folder_name to $save_dir"

    if [[ $clean_dir == *"$install_dir"* ]]; then
        result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$save_dir/$folder_name")
        checkSuccess "Updating $folder_name with $CFG_DOCKER_INSTALL_USER ownership"
    else
        result=$(sudo chown $easydockeruser:$easydockeruser "$save_dir/$folder_name")
        checkSuccess "Updating $folder_name with $easydockeruser ownership"
    fi
}

copyFolders() 
{
    local source="$1"
    local save_dir="$2"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    # Ensure the source path is expanded to a list of subdirectories
    local subdirs=($(find "$source" -mindepth 1 -maxdepth 1 -type d))

    if [ ${#subdirs[@]} -eq 0 ]; then
        echo "No subdirectories found in the source directory: $source"
        return
    fi

    for subdir in "${subdirs[@]}"; do
        local subdir_name=$(basename "$subdir")

        result=$(sudo cp -rf "$subdir" "$save_dir")
        checkSuccess "Copying $subdir_name to $save_dir"

        if [[ $clean_dir == *"$install_dir"* ]]; then
            result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$save_dir/$subdir_name")
            checkSuccess "Updating $subdir_name with $CFG_DOCKER_INSTALL_USER ownership"
        else
            result=$(sudo chown -R $easydockeruser:$easydockeruser "$save_dir/$subdir_name")
            checkSuccess "Updating $subdir_name with $easydockeruser ownership"
        fi
    done
}

copyResource() 
{
    local app_name="$1"
    local file_name="$2"
    local save_path="$3"

    local app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)

    # Check if the app_name folder was found
    if [ -z "$app_dir" ]; then
        echo "App folder '$app_name' not found in '$containers_dir'."
    fi

    result=$(sudo cp "$app_dir/resources/$file_name" "$install_dir$app_name$save_path")
    checkSuccess "Copying $file_name to $install_dir$app_name$save_path"
}

copyFile() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local save_dir="$2"
    local save_dir_file=$(basename "$save_dir")
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    result=$(sudo cp "$file" "$save_dir")
    checkSuccess "Copying $file_name to $save_dir"

    if [[ $clean_dir == *"$install_dir"* ]]; then
        result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$save_dir")
        checkSuccess "Updating $save_dir_file with $CFG_DOCKER_INSTALL_USER ownership"
    else
        result=$(sudo chown $easydockeruser:$easydockeruser "$save_dir")
        checkSuccess "Updating $save_dir_file with $easydockeruser ownership"
    fi
}

copyFiles() 
{
    local source="$1"
    local save_dir="$2"
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    # Ensure the source path is expanded to a list of files
    local files=($(find "$source" -type f))

    if [ ${#files[@]} -eq 0 ]; then
        echo "No files found in the source directory: $source"
        return
    fi

    for file in "${files[@]}"; do
        local file_name=$(basename "$file")

        result=$(sudo cp -f "$file" "$save_dir")
        checkSuccess "Copying $file_name to $save_dir"

        if [[ $clean_dir == *"$install_dir"* ]]; then
            result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$save_dir/$file_name")
            checkSuccess "Updating $file_name with $CFG_DOCKER_INSTALL_USER ownership"
        else
            result=$(sudo chown $easydockeruser:$easydockeruser "$save_dir/$file_name")
            checkSuccess "Updating $file_name with $easydockeruser ownership"
        fi
    done
}

createTouch() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local file_dir=$(dirname "$file")
    local clean_dir=$(echo "$file" | sed 's#//*#/#g')

    result=$(sudo touch "$clean_dir")
    checkSuccess "Touching $file_name to $file_dir"

    if [[ $clean_dir == *"$install_dir"* ]]; then
        result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$file")
        checkSuccess "Updating $file_name with $CFG_DOCKER_INSTALL_USER ownership"
    else
        result=$(sudo chown $easydockeruser:$easydockeruser "$file")
        checkSuccess "Updating $file_name with $easydockeruser ownership"
    fi
}

updateFileOwnership() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local clean_dir=$(echo "$file" | sed 's#//*#/#g')
    local user_name="$2"

    if [[ $clean_dir == *"$install_dir"* ]]; then
        result=$(sudo chown $user_name:$user_name "$file")
        checkSuccess "Updating $file_name with $user_name ownership"
    else
        result=$(sudo chown $easydockeruser:$easydockeruser "$file")
        checkSuccess "Updating $file_name with $easydockeruser ownership"
    fi
}

zipFile() 
{
    local passphrase="$1"
    local zip_file="$2"
    local zip_directory="$3"

    # Run the SSH command using the existing SSH variables
    result=$(sudo zip -r -MM -e -P $passphrase $zip_file $zip_directory)
    checkSuccess "Zipped up $(basename "$zip_file")"

    result=$(sudo chown $easydockeruser:$easydockeruser "$zip_file")
    checkSuccess "Updating $(basename "$zip_file") with $easydockeruser ownership"
}
