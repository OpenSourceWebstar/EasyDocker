#!/bin/bash

databaseAppScan() 
{
    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if database file is available
    if [ ! -f "$docker_dir/$db_file" ] ; then
        isNotice "Database file not found. Make sure it's installed."
        return 1
    fi

    echo ""
    echo "##########################################"
    echo "###  Scanning Docker folder for apps   ###"
    echo "##########################################"
    echo ""

    # Check if the folder exists
    if [ ! -d "$containers_dir" ]; then
        checkSuccess "Install path not found or not a directory: $containers_dir"
        return 1
    fi

    # Scan the folder and retrieve folder names
    local folder_names=$(sudo find "$containers_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

    # Check if no folders are found
    if [ -z "$folder_names" ]; then
        checkSuccess "No apps found."
        return
    fi

    # Initialize the updated_count variable to keep track of updates made to the database
    local updated_count=0

    # Get the list of all folder names and statuses from the database
    local existing_folders=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name, status, uninstall_date FROM apps;")

    # Create an array to store existing folder names in the database
    local existing_folder_names=()
    while IFS='|' read -r folder_name status uninstall_date; do
        if [[ -n "$folder_name" ]]; then
            existing_folder_names+=("$folder_name")
            # Check if the folder exists in the containers_dir
            if [ -d "$containers_dir/$folder_name" ]; then
                if (( status == 0 )); then 
                    isNotice "The folder for $folder_name has been found."
                    # Update the database to set the status to 1 (installed) and unset the uninstall_date
                    local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET status = 1, uninstall_date = NULL WHERE name = '$folder_name';")
                    checkSuccess "Updating apps database for $folder_name to installed status."
                    ((updated_count++)) # Increment updated_count
                fi
            fi
        fi
    done <<< "$existing_folders"

    # Loop through immediate subdirectories of $containers_dir
    for app_dir in "$containers_dir"/*/; do
        # Get the app name from the folder name
        local app_name=$(basename "$app_dir")

        # Check if the app name is not already in the database
        if ! [[ " ${existing_folder_names[@]} " =~ " $app_name " ]]; then
            # Check if the folder contains a valid .config file
            if [ -f "$app_dir/$app_name.config" ]; then
                # Extract the date and time from the folder name (if present)
                local folder_datetime=$(sudo echo "$app_name" | sudo grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}')
                if [ -z "$folder_datetime" ]; then
                    # If no date and time are found in the folder name, use the current date and time
                    local folder_datetime=$(sudo date "+%Y-%m-%d %H:%M:%S")
                fi

                # Split folder_datetime into date and time variables
                local folder_date=$(echo "$folder_datetime" | awk '{print $1}')
                local folder_time=$(echo "$folder_datetime" | awk '{print $2}')

                # Add the new entry to the database with a default status of 1 (installed) and the extracted or current date
                local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO apps (name, status, install_date, install_time) VALUES ('$app_name', 1, '$folder_date', '$folder_time');")
                checkSuccess "Adding $app_name to the apps database."
                ((updated_count++)) # Increment updated_count
            fi
        fi
    done

    # Create an array to store folder names that should be removed from the database
    local folders_to_remove=()

    # Get a list of folder names that exist in the database but not in the current folder structure
    for folder_name in "${existing_folder_names[@]}"; do
        if [ ! -d "$containers_dir/$folder_name" ]; then
            local folders_to_remove+=("$folder_name")
        fi
    done

    # Get a list of folder names that exist in the database but not in the current folder structure
    for folder_name in "${existing_folder_names[@]}"; do
        if [ ! -d "$containers_dir/$folder_name" ]; then
            # Check if this folder is actually associated with an entry in the database
            if [[ " ${folder_names[@]} " =~ " $folder_name " ]]; then
                isNotice "Folder $folder_name no longer exists. Removing from the Database."

                # Delete the entry from the apps table
                local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM apps WHERE name = '$app_name';")
                checkSuccess "Removing $app_name from the apps database."

                portsRemoveFromDatabase $app_name;

                ((updated_count++)) # Increment updated_count
            fi
        fi
    done

    # Check if all apps are up to date
    if [ "$updated_count" -eq 0 ]; then
        checkSuccess "All apps are up to date."
    fi

    # Check and uninstall apps that contain only a config file, are empty, have only a migrate.txt file, or both
    for folder_name in $folder_names; do
        folder_path="$containers_dir/$folder_name"
        if [ -d "$folder_path" ]; then
            local num_files=$(sudo find "$folder_path" -maxdepth 1 -type f | wc -l)
            
            # Check if the folder is empty, contains only a config file, has only a migrate.txt file, or contains both
            if [ "$num_files" -eq 0 ]; then
                isNotice "Uninstalling $folder_name because it is empty."
                if [[ "$CFG_REQUIREMENT_AUTO_CLEAN_FOLDERS" != "true" ]]; then
                    while true; do
                        echo ""
                        isQuestion "Would you like to remove $folder_name? *THIS WILL WIPE ALL DATA* (y/n): "
                        read -p "" found_empty_remove_choice
                        if [[ -n "$found_empty_remove_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$found_empty_remove_choice" == [yY] ]]; then
                        dockerUninstallApp "$folder_name";
                    fi
                else
                    dockerUninstallApp "$folder_name";
                fi
            elif [ "$num_files" -eq 1 ] && [ -f "$folder_path/$folder_name.config" ]; then
                isNotice "Uninstalling $folder_name because it contains only a config file."
                if [[ "$CFG_REQUIREMENT_AUTO_CLEAN_FOLDERS" != "true" ]]; then
                    while true; do
                        echo ""
                        isQuestion "Would you like to remove $folder_name? *THIS WILL WIPE ALL DATA* (y/n): "
                        read -p "" found_empty_remove_choice
                        if [[ -n "$found_empty_remove_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$found_empty_remove_choice" == [yY] ]]; then
                        dockerUninstallApp "$folder_name";
                    fi
                else
                    dockerUninstallApp "$folder_name";
                fi
            elif [ "$num_files" -eq 1 ] && [ -f "$folder_path/migrate.txt" ]; then
                isNotice "Uninstalling $folder_name because it contains only a migrate.txt file."
                if [[ "$CFG_REQUIREMENT_AUTO_CLEAN_FOLDERS" != "true" ]]; then
                    while true; do
                        echo ""
                        isQuestion "Would you like to remove $folder_name? *THIS WILL WIPE ALL DATA* (y/n): "
                        read -p "" found_empty_remove_choice
                        if [[ -n "$found_empty_remove_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$found_empty_remove_choice" == [yY] ]]; then
                        dockerUninstallApp "$folder_name";
                    fi
                else
                    dockerUninstallApp "$folder_name";
                fi
            elif [ "$num_files" -eq 2 ] && [ -f "$folder_path/$folder_name.config" ] && [ -f "$folder_path/migrate.txt" ]; then
                isNotice "Uninstalling $folder_name because it contains both a config file and a migrate.txt file."
                if [[ "$CFG_REQUIREMENT_AUTO_CLEAN_FOLDERS" != "true" ]]; then
                    while true; do
                        echo ""
                        isQuestion "Would you like to remove $folder_name? *THIS WILL WIPE ALL DATA* (y/n): "
                        read -p "" found_empty_remove_choice
                        if [[ -n "$found_empty_remove_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$found_empty_remove_choice" == [yY] ]]; then
                        dockerUninstallApp "$folder_name";
                    fi
                else
                    dockerUninstallApp "$folder_name";
                fi
            fi
        else
            # If the folder doesn't exist in the directory, uninstall it from the database
            isNotice "Folder $folder_name does not exist. Removing from the Database."
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM apps WHERE name = '$folder_name';")
            checkSuccess "Removing $folder_name from the apps database."
            ((updated_count++)) # Increment updated_count
        fi
    done
}
