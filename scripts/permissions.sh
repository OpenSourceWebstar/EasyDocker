#!/bin/bash

fixFolderPermissions() 
{  
    # Docker install user setup
    result=$(echo -e "$CFG_DOCKER_INSTALL_PASS\n$CFG_DOCKER_INSTALL_PASS" | sudo passwd "$CFG_DOCKER_INSTALL_USER" > /dev/null 2>&1)
    checkSuccess "Adding execute permissions for $CFG_DOCKER_INSTALL_USER user"

    result=$(sudo chmod +x $base_dir $install_path)
    checkSuccess "Adding execute permissions for $CFG_DOCKER_INSTALL_USER user"

    result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$install_path")
    checkSuccess "Updating $install_path with $CFG_DOCKER_INSTALL_USER ownership"
}

runStart() 
{  
    local path="$3"
    cd $script_dir
    result=$(sudo -u $easydockeruser chmod 0755 start.sh)
    checkSuccess "Updating Start Script Permissions"
    
    result=$(sudo -u $easydockeruser ./start.sh "" "" "$path")
    checkSuccess "Running Start script"
}

runInit() 
{
    cd $script_dir
    result=$(sudo -u $easydockeruser chmod 0755 init.sh)
    checkSuccess "Updating Init Script Permissions"
    
    result=$(sudo -u $easydockeruser ./init.sh run)
    checkSuccess "Running Init Script"
}

runUpdate() 
{
    cd $script_dir
    result=$(sudo -u $easydockeruser chmod 0755 update.sh)
    checkSuccess "Updating Update Script Permissions"
    
    result=$(sudo -u $easydockeruser ./update.sh)
    checkSuccess "Running Update Script"
}

mkdirFolders() 
{
    for dir_path in "$@"; do
        local folder_name=$(basename "$dir_path")
        local clean_dir=$(echo "$dir_path" | sed 's#//*#/#g')

        result=$(sudo mkdir -p "$dir_path")
        checkSuccess "Creating $folder_name directory"
        if [[ $clean_dir == *"$install_path"* ]]; then
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

    if [[ $clean_dir == *"$install_path"* ]]; then
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

        if [[ $clean_dir == *"$install_path"* ]]; then
            result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$save_dir/$subdir_name")
            checkSuccess "Updating $subdir_name with $CFG_DOCKER_INSTALL_USER ownership"
        else
            result=$(sudo chown -R $easydockeruser:$easydockeruser "$save_dir/$subdir_name")
            checkSuccess "Updating $subdir_name with $easydockeruser ownership"
        fi
    done
}

copyFile() 
{
    local file="$1"
    local file_name=$(basename "$file")
    local save_dir="$2"
    local save_dir_file=$(basename "$save_dir")
    local clean_dir=$(echo "$save_dir" | sed 's#//*#/#g')

    result=$(sudo cp "$file" "$save_dir")
    checkSuccess "Coping $file_name to $save_dir"

    if [[ $clean_dir == *"$install_path"* ]]; then
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

        if [[ $clean_dir == *"$install_path"* ]]; then
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

    if [[ $clean_dir == *"$install_path"* ]]; then
        result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$file")
        checkSuccess "Updating $file_name with $CFG_DOCKER_INSTALL_USER ownership"
    else
        result=$(sudo chown $easydockeruser:$easydockeruser "$file")
        checkSuccess "Updating $file_name with $easydockeruser ownership"
    fi
}
