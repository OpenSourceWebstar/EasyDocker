#!/bin/bash

migrateGenerateTXTAll()
{
    echo ""
    echo "############################################"
    echo "######       Migration Install        ######"
    echo "############################################"
    echo ""
    # Loop through subdirectories
    for folder in "$install_path"/*; do
        if [ -d "$folder" ]; then
            # Check if a migrate.txt file exists in the current directory
            if [ ! -f "$folder/$migrate_file" ]; then
                migrateBuildTXT $folder;
            fi
        fi
    done

    isSuccessful "Scanning and creating migrate.txt files completed."
}

migrateScanFoldersForUpdates()
{
    # Loop through all directories in the install path
    for folder in "$install_path"/*; do
        if [ -d "$folder" ]; then
            migrateCheckAndUpdateIP $folder;
            migrateCheckAndUpdateInstallName $folder;
        fi
    done

    isSuccessful "Migration IP checking and updating completed."
}

migrateGenerateTXTSingle()
{
    local folder=$1
    local app_name=$(basename "$folder")
    # Check if the specified directory exists
    if [ -d "$folder" ]; then
        # Check if a migrate.txt file already exists in the specified directory
        if [ ! -f "$folder/$migrate_file" ]; then
            migrateBuildTXT $folder;
        else
            isNotice "$migrate_file already exists for $app_name."
            while true; do
                isQuestion "Do you want to update $migrate_file to the local machine? (y/n): "
                read -rp "" replacemigration
                if [[ "$replacemigration" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done
            if [[ "$replacemigration" == [yY] ]]; then
                migrateBuildTXT $folder;
            fi
        fi
    else
        isNotice "The specified directory $app_name does not exist."
    fi

    isSuccessful "Generating $migrate_file for $app_name completed."
}

migrateBuildTXT()
{
    local folder=$1
    local app_name=$(basename "$folder")

    # Create a migrate.txt file with IP and InstallName
    touch "$folder/$migrate_file"
    
    # Add MIGRATE options to file
    echo "MIGRATE_IP=$public_ip" > "$install_path/$app_name/$migrate_file" 2>/dev/null
    echo "MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME" >> "$install_path/$app_name/$migrate_file" 2>/dev/null
    
    isSuccessful "Created $migrate_file for $app_name"
}

migrateCheckAndUpdateIP()
{
    local folder="$1"
    local app_name=$(basename "$folder")
    # Check if the migrate.txt file exists
    if [ -f "$folder/$migrate_file" ]; then
        local migrate_ip=$(grep -o 'MIGRATE_IP=.*' "$folder/$migrate_file" | cut -d '=' -f 2)
        if [ "$migrate_ip" != "$public_ip" ]; then
            result=$(sed -i "s/MIGRATE_IP=.*/MIGRATE_IP=$public_ip/" "$folder/$migrate_file")
            checkSuccess "Updated MIGRATE_IP in $migrate_file to $public_ip."

            # Replace old IP with $public_ip in .yml and .env files
            result=$(find "$folder" -type f \( -name "*.yml" -o -name "*.env" \) -exec sed -i "s/$migrate_ip/$public_ip/g" {} \;)
            checkSuccess "Replaced old IP with $public_ip in .yml and .env files in $app_name."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}

migrateCheckAndUpdateInstallName() 
{
    local folder="$1"
    local app_name=$(basename "$folder")
    # Check if the migrate.txt file exists
    if [ -f "$folder/$migrate_file" ]; then
        local migrate_install_name=$(grep -o 'MIGRATE_INSTALL_NAME=.*' "$folder/$migrate_file" | cut -d '=' -f 2)
        if [ "$migrate_install_name" != "$CFG_INSTALL_NAME" ]; then
            result=$(sed -i "s/MIGRATE_INSTALL_NAME=.*/MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME/" "$folder/$migrate_file")
            checkSuccess "Updated MIGRATE_INSTALL_NAME in $migrate_file to $CFG_INSTALL_NAME."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}
