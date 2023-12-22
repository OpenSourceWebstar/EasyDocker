#!/bin/bash

databaseInstallApp() 
{
    local app_name="$1"

    # Check if sqlite3 is available
    if ! command -v sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 1
    fi

    # Check if the app_name is provided
    if [ -z "$app_name" ]; then
        isNotice "App name not provided. Will not continue..."
        return 1
    fi

    # Check if the app exists in the database
    app_exists=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM apps WHERE name = '$app_name';")

    if [ "$app_exists" -eq 0 ]; then
        isNotice "App does not exist in the database, setting up now."
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO apps (name, status, install_date, install_time) VALUES ('$app_name', '1', '$current_date', '$current_time');")
        checkSuccess "Adding $app_name to the apps database."
        echo ""
    else
        isNotice "App already exists in the database, updating now."
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET status = '1', install_date = '$current_date', install_time = '$current_time', uninstall_date = NULL WHERE name = '$app_name';")
        checkSuccess "Updating apps database for $app_name to installed status."
        echo ""
    fi
}

databaseUninstallApp() 
{
    local app_name="$1"
    
    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 1
    fi

    if [ -z "$app_name" ]; then
        isNotice "App name not provided. Will not continue..."
        return 1
    fi

    # Check if the app exists in the database
    results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE name = '$app_name'")

    if [ -z "$results" ]; then
        # App not found in the database
        isNotice "$app_name is not installed or not found in the database."
        return 1
    else
        # App found in the database, update status to 0 and set uninstall_date
        isNotice "Uninstalling $app_name..."
        if ! sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET status = 0, uninstall_date = '$current_date', uninstall_time = '$current_time' WHERE name = '$app_name';"; then
            isError "Failed to update the database for $app_name."
            return 1
        fi
        isSuccessful "$app_name successfully uninstalled."
    fi
}

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

                removePortsFromDatabase $app_name;

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
                        uninstallApp "$folder_name";
                    fi
                else
                    uninstallApp "$folder_name";
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
                        uninstallApp "$folder_name";
                    fi
                else
                    uninstallApp "$folder_name";
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
                        uninstallApp "$folder_name";
                    fi
                else
                    uninstallApp "$folder_name";
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
                        uninstallApp "$folder_name";
                    fi
                else
                    uninstallApp "$folder_name";
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

databaseListAllApps()
{
	if [[ "$toollistallapps" == [yY] ]]; then
    
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
        echo "###     Listing full apps database     ###"
        echo "##########################################"
        echo ""

        # Execute the SQLite query and store the output in a variable
        local output=$(sudo sqlite3 -header -column $docker_dir/$db_file "SELECT * FROM apps;")
        # Count the number of non-header lines (data rows) in the 'output'
        local num_data_rows=$(echo "$output" | grep -v '^name[[:space:]]|')

        # Check if results variable is not empty
        if [ -n "$num_data_rows" ]; then
            # Loop through each line of the output and print it as a list item
            echo "$output" | while IFS= read -r line; do
                echo "$line"
            done
            read -p "Press Enter to continue..."
            else
            isNotice "No applications found"
        fi
    fi
}

databaseListInstalledApps() 
{
    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if database file is available
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found. Make sure it's installed."
        return 1
    fi

    echo ""
    echo "##########################################"
    echo "###       Listing installed apps       ###"
    echo "##########################################"
    echo ""

    # Check if the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 1
    fi

    # Execute the query and store the results in a variable for installed apps only (status = 1)
    local results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT apps.name, apps.install_date, apps.install_time, GROUP_CONCAT(ports.port, ',') AS Ports FROM apps LEFT JOIN ports ON apps.name = ports.name WHERE apps.status = 1 GROUP BY apps.name;")

    # Check if results variable is not empty
    if [ -n "$results" ]; then
        # Print the column headers
        printf "%-12s| %-12s | %-12s | %-12s\n" "Name" "Install Date" "Install Time" "Ports"
        echo "-------------------------------------------------"

        # Read and print each row of the results
        while IFS="|" read -r name install_date install_time ports; do
            if [ -z "$install_date" ]; then
                # If install_date is empty, update it with the current date
                install_date=$(date +"%Y-%m-%d")
                sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET install_date = '$install_date' WHERE name = '$name';"
            fi
            if [ -z "$install_time" ]; then
                # If install_time is empty, update it with the current time
                install_time=$(date +"%H:%M:%S")
                sudo sqlite3 "$docker_dir/$db_file" "UPDATE apps SET install_time = '$install_time' WHERE name = '$name';"
            fi
            printf "%-12s| %-12s | %-12s | %-12s\n" "$name" "$install_date" "$install_time" "$ports"
        done <<< "$results"

        if [[ "$toollistinstalledapps" == [yY] ]]; then
            read -p "Press Enter to continue..."
        fi
    else
        isSuccessful "No apps found."
    fi
}

databaseCycleThroughListApps()
{
    local name=$1
    # Protection from running in start script
    if [[ "$backupsingle" == [yY] ]] || [[ "$backupfull" == [yY] ]] || [[ "$migratesingle" == [yY] ]] || [[ "$migratefull" == [yY] ]]; then

        # Full
        # Backup
        if [[ "$backupfull" == [yY] ]]; then
            local name=full
            isQuestion "Do you want a $name Backup? (y/n) "
            read -rp "" BACKUPACCEPT

            if [[ $BACKUPACCEPT == [yY] ]]; then
                isNotice "Starting a $name backup."
                backupInitialize $name
            fi
        fi

        # Migrate
        if [[ "$migratefull" == [yY] ]]; then
            local name=full
            isQuestion "Do you want a $name Migration  (y/n)? "
            read -rp "" MIGRATEACCEPT

            if [[ $MIGRATEACCEPT == [yY] ]]; then
                isNotice "Starting a $name migrate."
                migrateStart $name
            fi
        fi

        # This is for single apps ONLY    
        local app_names=()
        while IFS= read -r name; do
            local app_names+=("$name")
        done < <(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1;")

        # Check if sqlite3 is available
        if ! command -v sudo sqlite3 &> /dev/null; then
            isNotice "sqlite3 command not found. Make sure it's installed."
            return 1
        fi

        # Check if the database file exists
        if [ ! -f "$docker_dir/$db_file" ]; then
            isNotice "Database file not found: $docker_dir/$db_file"
            return 1
        fi

        # Backup
        if [[ "$backupsingle" == [yY] ]]; then
            for name in "${app_names[@]}"; do
                isQuestion "Do you want a $name Backup? (y/n) "
                read -rp "" BACKUPACCEPT

                if [[ $BACKUPACCEPT == [yY] ]]; then
                    isNotice "Starting a $name backup."
                    backupInitialize $name  
                fi
            done
        fi

        # Migrate
        if [[ "$migratesingle" == [yY] ]]; then
            for name in "${app_names[@]}"; do
                isQuestion "Do you want a $name Migration  (y/n)? "
                read -rp "" MIGRATEACCEPT


                if [[ $MIGRATEACCEPT == [yY] ]]; then
                    isNotice "Starting a $name migration."
                    migrateStart $name
                fi
            done
        fi

	fi
}

databaseCycleThroughListAppsCrontab() 
{
    local show_header=$1
    local ISCRON=$( (sudo -u $sudo_user_name crontab -l) 2>&1 )

    # Check to see if installed
    if [[ "$ISCRON" == *"command not found"* ]]; then
        isNotice "Crontab is not found. Unable to set up backups."
        return 1
    fi

    # Check to see if crontab is not installed
    if ! sudo -u $sudo_user_name crontab -l | grep -q "cron is set up for $sudo_user_name" > /dev/null 2>&1; then
        isNotice "Crontab is not set up, skipping until it's found."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 1
    fi

    if [[ $show_header != "false" ]]; then
        echo ""
        echo "############################################"
        echo "######     Backup Crontab Install     ######"
        echo "############################################"
    fi

    local app_names=("full")  # To Inject full to set up crontab also
    while IFS= read -r name; do
        local app_names+=("$name")
    done < <(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1;")

    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Remove crontab entries for applications with status = 0 (uninstalled)
    while IFS= read -r name; do
        local uninstalled_apps+=("$name")
    done < <(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 0;")

    for name in "${uninstalled_apps[@]}"; do
        removeBackupCrontabAppFolderRemoved $name
    done

    # Setup crontab entries for installed applications
    for name in "${app_names[@]}"; do
        checkBackupCrontabApp $name
    done

    echo ""
    isSuccessful "Setting up Crontab backups for application(s) completed."
}


# Function to scan the folder for missing .pub keys and process them
databaseSSHScanForKeys() 
{
    echo ""
    echo "############################################"
    echo "######          SSH Key Scan          ######"
    echo "############################################"
    echo ""

    local ssh_directory="$ssh_dir$CFG_DOCKER_MANAGER_USER"

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

    # Remove old keys from the authorized_keys file and the database
    updateAuthorizedKeysAndDatabase "$ssh_directory"

    updateSSHPermissions

    # Reloading SSH Service
    local result=$(sudo service ssh reload)
    checkSuccess "Reloading the SSH Service"

    isSuccessful "SSH Key Scan completed successfully."
}

databaseDisplayTables() 
{
    if [[ "$toollistalltables" == [yY] ]]; then
        local table_number=0
        local selected_table=""
        local sorted_tables=()

        echo ""
        echo "##########################################"
        echo "###      View Database Table Data      ###"
        echo "##########################################"
        echo ""

        while true; do
            # Check if sqlite3 is available
            if ! command -v sudo sqlite3 &> /dev/null; then
                isNotice "sqlite3 command not found. Make sure it's installed."
                return 1
            fi

            # Ensure the database file exists
            if [ ! -f "$docker_dir/$db_file" ]; then
                isNotice "Database file not found: $docker_dir/$db_file"
                return
            fi

            # Get a list of existing tables in the database
            local tables_list=($(sudo sqlite3 "$docker_dir/$db_file" ".tables"))

            # Sort the tables alphabetically
            sorted_tables=($(printf "%s\n" "${tables_list[@]}" | sort))

            # Check if there are any tables in the database
            if [ "${#sorted_tables[@]}" -eq 0 ]; then
                isError "No tables found in the database."
                return
            fi

            table_number=0
            for table_name in "${sorted_tables[@]}"; do
                table_number=$((table_number+1))
                echo "$table_number. $table_name"
            done

            echo ""
            isQuestion "Enter the number of the table to view data (x to exit): "
            read -p "" selected_table

            if [[ "$selected_table" == "x" ]]; then
                echo ""
                echo "Exiting."
                return
            elif [[ "$selected_table" =~ ^[0-9]+$ ]] && ((selected_table >= 1)) && ((selected_table <= "${#sorted_tables[@]}")); then
                selected_table="${sorted_tables[$((selected_table-1))]}"
                # Display all data for the selected table with formatted output
                echo ""
                echo "##########################################"
                echo "###   Displaying $selected_table Table Data"
                echo "##########################################"
                echo ""
                sudo sqlite3 -column -header "$docker_dir/$db_file" "SELECT * FROM $selected_table;"
                echo ""
                isQuestion "Press Enter to continue..."
                read -p "" input
            else
                isNotice "Invalid table number. Please try again."
            fi
        done
    fi
}

databaseEmptyTable() 
{
  if [[ "$toolemptytable" == [yY] ]]; then
    echo ""
    echo "#######################################"
    echo "###      Empty Database Table       ###"
    echo "#######################################"
    echo ""

    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
      isNotice "sqlite3 command not found. Make sure it's installed."
      return 1
    fi

    # Ensure the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
      isNotice "Database file not found: $docker_dir/$db_file"
      return
    fi

    # Get a list of existing tables in the database
    local tables_list=$(sudo sqlite3 "$docker_dir/$db_file" ".tables")

    # Check if there are any tables in the database
    if [ -z "$tables_list" ]; then
      isNotice "No tables found in the database."
      return
    fi

    # Display the numbered list of tables
    echo "=== List of Tables ==="
    while IFS= read -r table_name; do
      echo "$table_name"
    done <<< "$tables_list"

    echo ""
    isQuestion "Enter the table name to empty (x to exit): "
    read -p "" table_name
    echo ""
    if [[ "$table_name" == "x" ]]; then
      isNotice "Exiting."
      return
    elif sudo sqlite3 "$docker_dir/$db_file" ".tables" | grep -q "\b$table_name\b"; then
      # Empty the selected table
      sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM \"$table_name\";"
      isSuccessful "Table '$table_name' has been emptied."
    else
      isNotice "Invalid table name. Please try again."
    fi
  fi
}

# Function to check is we should run the update
checkIfUpdateShouldRun() 
{
    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
      isNotice "sqlite3 command not found. Make sure it's installed."
      return 0
    fi

    # Ensure the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
        isNotice "Database file not found: $docker_dir/$db_file"
        return 0  # Database doesn't exist, so we should run the update
    fi

    local table_name="sysupdate"
    local latest_timestamp=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT datetime(date || ' ' || time) FROM \"$table_name\" ORDER BY date DESC, time DESC LIMIT 1;")

    # Check if the timestamp is empty or not (no records in the database)
    if [[ -n "$latest_timestamp" ]]; then
        # Convert the latest timestamp to UNIX timestamp (seconds since epoch)
        local latest_timestamp_unix=$(date -d "$latest_timestamp" +%s)

        # Get the current UNIX timestamp
        local current_timestamp_unix=$(date +%s)

        # Calculate the time difference in seconds (current - latest)
        local time_difference=$((current_timestamp_unix - latest_timestamp_unix))

        # Define the time threshold in seconds (config_value_minutes * 60)
        local threshold=$(($CFG_UPDATER_CHECK * 60))

        # Compare the time difference with the threshold
        if ((time_difference >= threshold)); then
            # The command can be executed since it hasn't been executed within the specified duration
            # Update the database with the latest current date and time
            sudo sqlite3 "$docker_dir/$db_file" "UPDATE \"$table_name\" SET date='$current_date', time='$current_time' WHERE ROWID=1;"
            return 0  # Return true (0)
        else
            # The command was executed recently, so skip it
            return 1  # Return false (1)
        fi
    else
        # If there are no records in the database, execute the command and insert the update data
        sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO \"$table_name\" (date, time) VALUES ('$current_date', '$current_time');"
        return 0  # Return true (0)
    fi
}

databasePathInsert()
{
    local initial_path_save="$1"
    if [ -f "$docker_dir/$db_file" ] && [ -n "$initial_path_save" ]; then
        local table_name=path
        # Check if the path already exists in the database
        local existing_path=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT path FROM $table_name WHERE path = '$initial_path_save';")
        if [ -z "$existing_path" ]; then
            # Path doesn't exist, clear old data and insert
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM $table_name;")
            checkSuccess "Clearing old path data"
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (path) VALUES ('$initial_path_save');")
            checkSuccess "Adding $initial_path_save to the $table_name table."
        fi
    fi
}

databasePortInsert()
{
    local app_name="$1"
    local port="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports
        # Check if already exists in the database
        local existing_portdata=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM $table_name WHERE name = '$app_name' AND port = '$port';")
        if [ -z "$existing_portdata" ]; then
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, port) VALUES ('$app_name', '$port');")
            checkSuccess "Adding port $port for $app_name to the $table_name table."
        fi
    fi
}

databasePortOpenInsert()
{
    local app_name="$1"
    local portdata="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports_open
        # Split the portdata into port and type
        IFS='/' read -r port type <<< "$portdata"
        # Check if already exists in the database
        local existing_portdata=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM $table_name WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
        if [ -z "$existing_portdata" ]; then
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, port, type) VALUES ('$app_name', '$port', '$type');")
            checkSuccess "Adding port $port and type $type for $app_name to the $table_name table."
        fi
    fi
}

databasePortRemove()
{
    local app_name="$1"
    local port="$2"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM $table_name WHERE name = '$app_name' AND port = '$port';")
        checkSuccess "Deleting port $port for $app_name for the $table_name table."
    fi
}

databasePortOpenRemove()
{
    local app_name="$1"
    local portdata="$2"

    # Split the portdata into port and type
    IFS='/' read -r port type <<< "$portdata"

    if [ -f "$docker_dir/$db_file" ] && [ -n "$app_name" ]; then
        local table_name=ports_open
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM $table_name WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
        checkSuccess "Deleting port $port and type $type for $app_name for the $table_name table."
    fi
}

databaseGetOpenPorts()
{
    local app_name="$1"
    local ports_open=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port || '/' || type FROM ports_open WHERE name = '$app_name';")
    echo "$ports_open"
}

databaseGetOpenPort()
{
    local app_name="$1"
    local port="$2"
    local type="$3"
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM ports_open WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
    checkSuccess "Removing open port entry for $usedport1/$type of $app_name from the database."
}

databaseGetUsedPorts()
{
    local app_name="$1"
    local used_ports=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM ports WHERE name = '$app_name';")
    echo "$used_ports"
}

databaseRemoveUsedPort()
{
    local app_name="$1"
    local port="$2"
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "DELETE FROM ports WHERE name = '$app_name' AND port = '$port';")
    checkSuccess "Removing used port entry for $port of $app_name from the database."
}

databaseGetUsedPortsForApp() 
{
    local app_name="$1"
    local used_ports=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM ports WHERE name = '$app_name';")
    local db_ports=()
    IFS=$'\n' read -r -a db_ports <<< "$used_ports"
    echo "${db_ports[@]}"
}

databaseGetOpenPortsForApp() 
{
    local app_name="$1"
    local ports_open=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT port FROM ports_open WHERE name = '$app_name';")
    local db_ports_open=()
    IFS=$'\n' read -r -a db_ports_open <<< "$ports_open"
    echo "${db_ports_open[@]}"
}

databaseBackupInsert()
{
    local app_name="$1"
    local table_name=backups
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table."    
}

databaseRestoreInsert()
{
    local app_name="$1"
    local table_name=restores
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table."
}

databaseMigrateInsert()
{
    local app_name="$1"
    local table_name=migrations
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table." 
}

databaseSSHInsert()
{
    local app_name="$1"
    local table_name=ssh
    local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (ip, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table." 
}

databaseSSHKeysInsert()
{
    local key_filename="$1"
    local key_file=$(basename "$key_filename")
    local table_name=ssh_keys
    local key_in_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE name = '$key_file';")

    if [ "$key_in_db" -eq 0 ]; then
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$key_file', '$current_date', '$current_time');")
        checkSuccess "Adding $key_file to the $table_name table."
    else
        local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE $table_name SET name = '$key_file', date = '$current_date', time = '$current_time' WHERE name = '$key_file';")
        checkSuccess "$key_file already added to the $table_name table. Updating date/time."
    fi
}

databaseCronJobsInsert()
{
    local app_name="$1"
    local table_name=cron_jobs
    local key_in_db=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE name = '$app_name';")

    if [ "$key_in_db" != "" ]; then
        if [ "$key_in_db" -eq 0 ]; then
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
            checkSuccess "Adding $app_name to the $table_name table." 
        else
            local result=$(sudo sqlite3 "$docker_dir/$db_file" "UPDATE $table_name SET name = '$app_name', date = '$current_date', time = '$current_time' WHERE name = '$app_name';")
            checkSuccess "$app_name already added to the $table_name table. Updating date/time." 
        fi
        #isNotice "app_name is empty, unable to insert"
    fi
}

databaseRemoveFile()
{
	if [[ "$tooldeletedb" == [yY] ]]; then
        local result=$(sudo -u $sudo_user_name rm $docker_dir/$db_file)
        checkSuccess "Removing $db_file file"
    fi
}