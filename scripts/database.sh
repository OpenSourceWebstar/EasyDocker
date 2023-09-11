#!/bin/bash

app_name="$1"

databaseInstallApp() {
    # Check if sqlite3 is available
    if ! command -v sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$base_dir/$db_file" ]; then
        isNotice "Database file not found: $base_dir/$db_file"
        return 1
    fi

    # Check if the app_name is provided
    if [ -z "$app_name" ]; then
        isNotice "App name not provided. Will not continue..."
        return 1
    fi

    # Check if the app exists in the database
    app_exists=$(sudo sqlite3 "$base_dir/$db_file" "SELECT COUNT(*) FROM apps WHERE name = '$app_name';")

    if [ "$app_exists" -eq 0 ]; then
        isNotice "App does not exist in the database, setting up now."
        result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO apps (name, status, install_date) VALUES ('$app_name', 1, date('now'));")
        checkSuccess "Adding $app_name to the apps database."
        echo ""
    else
        isNotice "App already exists in the database, updating now."
        result=$(sudo sqlite3 "$base_dir/$db_file" "UPDATE apps SET status = 1, uninstall_date = NULL WHERE name = '$app_name';")
        checkSuccess "Updating apps database for $app_name to installed status."
        echo ""
    fi
}

databaseUninstallApp() 
{
    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$base_dir/$db_file" ]; then
        isNotice "Database file not found: $base_dir/$db_file"
        return 1
    fi

    if [ -z "$app_name" ]; then
        isNotice "App name not provided. Will not continue..."
        return 1
    fi

    # Check if the app exists in the database
    results=$(sudo sqlite3 "$base_dir/$db_file" "SELECT name FROM apps WHERE name = '$app_name'")

    if [ -z "$results" ]; then
        # App not found in the database
        isError "$app_name is not installed or not found in the database."
        return 1
    else
        # App found in the database, update status to 0 and set uninstall_date
        isNotice "Uninstalling $app_name..."
        if ! sudo sqlite3 "$base_dir/$db_file" "UPDATE apps SET status = 0, uninstall_date = date('now') WHERE name = '$app_name';"; then
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
    if [ ! -f "$base_dir/$db_file" ] ; then
        checkSuccess "Database file not found. Make sure it's installed."
        return 1
    fi

    echo ""
    echo "##########################################"
    echo "###  Scanning Docker folder for apps   ###"
    echo "##########################################"
    echo ""

    # Check if the folder exists
    if [ ! -d "$install_path" ]; then
        checkSuccess "Install path not found or not a directory: $install_path"
        return 1
    fi

    # Scan the folder and retrieve folder names
    folder_names=$(sudo find "$install_path" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

    # Check if no folders are found
    if [ -z "$folder_names" ]; then
        checkSuccess "No apps found."
        return
    fi

    # Initialize the updated_count variable to keep track of updates made to the database
    updated_count=0

    # Get the list of all folder names and statuses from the database
    existing_folders=$(sudo sqlite3 "$base_dir/$db_file" "SELECT name, status FROM apps;")

    # Create an array to store existing folder names in the database
    existing_folder_names=()
    while IFS='|' read -r folder_name status; do
        if [[ -n "$folder_name" ]]; then
        existing_folder_names+=("$folder_name")
            # Check if the folder exists in the install_path
            if [ -d "$install_path/$folder_name" ]; then
                if (( status != 1 )); then 
                    isNotice "The folder for $folder_name has been found. Updating status to Installed in the Database"
                    # Update the database to set the status to 1 (installed) and unset the uninstall_date
                    result=$(sudo sqlite3 "$base_dir/$db_file" "UPDATE apps SET status = 1, uninstall_date = NULL WHERE name = '$folder_name';")
                    checkSuccess "Updating apps database for $folder_name to installed status."
                    ((updated_count++)) # Increment updated_count
                fi
            else
                # Check if the status is not 0 (not uninstalled)
                if (( status != 0 )); then
                    isNotice "Unable to find the folder for $folder_name. Setting to Uninstalled in the Database"
                    # Update the database to set the status to 0 and set the uninstall_date to the current date
                    result=$(sudo sqlite3 "$base_dir/$db_file" "UPDATE apps SET status = 0, uninstall_date = date('now') WHERE name = '$folder_name';")
                    checkSuccess "Updating apps database for $folder_name to uninstalled status."
                    ((updated_count++)) # Increment updated_count
                fi
            fi
        fi
    done <<< "$existing_folders"

    # Insert folders into the database if they don't exist already
    for folder_name in $folder_names; do
        if [[ -n "$folder_name" ]]; then
            # Check if the folder_name is not present in the existing_folder_names array
            if ! [[ "${existing_folder_names[@]}" =~ "${folder_name}" ]]; then
                isNotice "New folder $folder_name found. Inserting into the Database."
                # Insert the new folder into the database with status 1 (installed)
                result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO apps (name, status, install_date) VALUES ('$folder_name', 1, date('now'));")
                checkSuccess "Inserting $folder_name into the apps database."
                ((updated_count++)) # Increment updated_count
            fi
        fi
    done

    # Check if all apps are up to date
    if [ "$updated_count" -eq 0 ]; then
        checkSuccess "All apps are up to date."
    fi
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
        if [ ! -f "$base_dir/$db_file" ] ; then
            checkSuccess "Database file not found. Make sure it's installed."
            return 1
        fi

        echo ""
        echo "##########################################"
        echo "###     Listing full apps database     ###"
        echo "##########################################"
        echo ""

        # Execute the SQLite query and store the output in a variable
        output=$(sudo sqlite3 -header -column $base_dir/$db_file "SELECT * FROM apps;")
        # Count the number of non-header lines (data rows) in the 'output'
        num_data_rows=$(echo "$output" | grep -v '^name[[:space:]]|')

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
    if [ ! -f "$base_dir/$db_file" ] ; then
        checkSuccess "Database file not found. Make sure it's installed."
        return 1
    fi

    echo ""
    echo "##########################################"
    echo "###       Listing installed apps       ###"
    echo "##########################################"
    echo ""

    # Check if the database file exists
    if [ ! -f "$base_dir/$db_file" ]; then
        isNotice "Database file not found: $base_dir/$db_file"
        return 1
    fi

    # Execute the query and store the results in a variable for installed apps only (status = 1)
    results=$(sudo sqlite3 "$base_dir/$db_file" "SELECT name, install_date FROM apps WHERE status = 1;")

    # Check if results variable is not empty
    if [ -n "$results" ]; then
        # Print the column headers
        printf "%-12s|%s\n" "Name" " Install Date"
        echo "--------------------------"

        # Read and print each row of the results
        while IFS="|" read -r name install_date; do
            printf "%-12s|%s\n" "$name" " $install_date"
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
            name=full
            isQuestion "Do you want a $name Backup? (y/n) "
            read -rp "" BACKUPACCEPT

            if [[ $BACKUPACCEPT == [yY] ]]; then
                isNotice "Starting a $name backup."
                backupInitialize $name
            fi
        fi

        # Migrate
        if [[ "$migratefull" == [yY] ]]; then
            name=full
            isQuestion "Do you want a $name Migration  (y/n)? "
            read -rp "" MIGRATEACCEPT

            if [[ $MIGRATEACCEPT == [yY] ]]; then
                isNotice "Starting a $name migrate."
                migrateStart $name
            fi
        fi

        # This is for single apps ONLY    
        app_names=()
        while IFS= read -r name; do
            app_names+=("$name")
        done < <(sudo sqlite3 "$base_dir/$db_file" "SELECT name FROM apps WHERE status = 1;")

        # Check if sqlite3 is available
        if ! command -v sudo sqlite3 &> /dev/null; then
            isNotice "sqlite3 command not found. Make sure it's installed."
            return 1
        fi

        # Check if the database file exists
        if [ ! -f "$base_dir/$db_file" ]; then
            isNotice "Database file not found: $base_dir/$db_file"
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
    local name=$1
    ISCRON=$( (sudo -u $easydockeruser crontab -l) 2>&1 )

    # Check to see if installed
    if [[ "$ISCRON" == *"command not found"* ]]; then
        isNotice "Crontab is not found. Unable to setup backups."
        return 1
    fi

    # Check to see if crontab is not installed
    if ! sudo -u $easydockeruser crontab -l | grep -q "cron is set up for $easydockeruser"; then
        isNotice "Crontab is not setup, skipping until its found."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$base_dir/$db_file" ]; then
        isNotice "Database file not found: $base_dir/$db_file"
        return 1
    fi

    echo ""
    echo "############################################"
    echo "######     Backup Crontab Install     ######"
    echo "############################################"

    app_names=("full")  # To Inject full to setup crontab also
    while IFS= read -r name; do
        app_names+=("$name")
    done < <(sudo sqlite3 "$base_dir/$db_file" "SELECT name FROM apps WHERE status = 1;")

    # Check if sqlite3 is available
    if ! command -v sudo sqlite3 &> /dev/null; then
        isNotice "sqlite3 command not found. Make sure it's installed."
        return 1
    fi

    # Check if the database file exists
    if [ ! -f "$base_dir/$db_file" ]; then
        isNotice "Database file not found: $base_dir/$db_file"
        return 1
    fi

    for name in "${app_names[@]}"; do
        installBackupCrontabApp $name
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
    if [ ! -f "$base_dir/$db_file" ] ; then
        isNotice "Database file not found. Make sure it's installed."
        return 1
    fi

    # Remove old keys from the authorized_keys file and the database
    updateAuthorizedKeysAndDatabase "$ssh_directory"

    updateSSHPermissions

    # Reloading SSH Service
    result=$(sudo service ssh reload)
    checkSuccess "Reloading the SSH Service"

    isSuccessful "SSH Key Scan completed successfully."
}

databaseDisplayTables() 
{
    if [[ "$toollistalltables" == [yY] ]]; then
        echo ""
        echo "##########################################"
        echo "###      View Database Table Data      ###"
        echo "##########################################"
        echo ""

        # Check if sqlite3 is available
        if ! command -v sudo sqlite3 &> /dev/null; then
            isNotice "sqlite3 command not found. Make sure it's installed."
            return 1
        fi

        # Ensure the database file exists
        if [ ! -f "$base_dir/$db_file" ]; then
            isNotice "Database file not found: $base_dir/$db_file"
            return
        fi

        # Get a list of existing tables in the database
        tables_list=$(sudo sqlite3 "$base_dir/$db_file" ".tables")

        # Check if there are any tables in the database
        if [ -z "$tables_list" ]; then
            isError "No tables found in the database."
            return
        fi

        while IFS= read -r table_name; do
            echo "$table_name"
        done <<<"$tables_list"

        echo ""
        isQuestion "Enter the table name to view data (x to exit): "
        read -p "" table_name
        echo ""

        if [[ "$table_name" == "x" ]]; then
            echo "Exiting."
        return
        elif sudo sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$table_name\b"; then
            # Display all data for the selected table with formatted output
            echo ""
            echo "##########################################"
            echo "###   Displaying $table_name Table Data"
            echo "##########################################"
            echo ""
            sudo sqlite3 -column -header "$base_dir/$db_file" "SELECT * FROM $table_name;"
            echo ""
            read -p "Press Enter to continue..."
        else
            isNotice "Invalid table name. Please try again."
        fi
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
    if [ ! -f "$base_dir/$db_file" ]; then
      isNotice "Database file not found: $base_dir/$db_file"
      return
    fi

    # Get a list of existing tables in the database
    tables_list=$(sudo sqlite3 "$base_dir/$db_file" ".tables")

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
    elif sudo sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$table_name\b"; then
      # Empty the selected table
      sudo sqlite3 "$base_dir/$db_file" "DELETE FROM \"$table_name\";"
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
    if [ ! -f "$base_dir/$db_file" ]; then
        isError "Database file not found: $base_dir/$db_file"
        return 0  # Database doesn't exist, so we should run the update
    fi

    local table_name="sysupdate"
    local latest_timestamp
    latest_timestamp=$(sudo sqlite3 "$base_dir/$db_file" "SELECT datetime(date || ' ' || time) FROM \"$table_name\" ORDER BY date DESC, time DESC LIMIT 1;")

    # Check if the timestamp is empty or not (no records in the database)
    if [[ -n "$latest_timestamp" ]]; then
        # Convert the latest timestamp to UNIX timestamp (seconds since epoch)
        local latest_timestamp_unix
        latest_timestamp_unix=$(date -d "$latest_timestamp" +%s)

        # Get the current UNIX timestamp
        local current_timestamp_unix
        current_timestamp_unix=$(date +%s)

        # Calculate the time difference in seconds (current - latest)
        local time_difference=$((current_timestamp_unix - latest_timestamp_unix))

        # Define the time threshold in seconds (config_value_minutes * 60)
        local threshold=$(($CFG_UPDATER_CHECK * 60))

        # Compare the time difference with the threshold
        if ((time_difference >= threshold)); then
            # The command can be executed since it hasn't been executed within the specified duration
            # Update the database with the latest current date and time
            sudo sqlite3 "$base_dir/$db_file" "UPDATE \"$table_name\" SET date='$current_date', time='$current_time' WHERE ROWID=1;"
            return 0  # Return true (0)
        else
            # The command was executed recently, so skip it
            return 1  # Return false (1)
        fi
    else
        # If there are no records in the database, execute the command and insert the update data
        sudo sqlite3 "$base_dir/$db_file" "INSERT INTO \"$table_name\" (date, time) VALUES ('$current_date', '$current_time');"
        return 0  # Return true (0)
    fi
}

databasePathInsert()
{
    local initial_path_save="$1"
    if [ -f "$base_dir/$db_file" ] && [ -n "$initial_path_save" ]; then
        table_name=path
        # Check if the path already exists in the database
        existing_path=$(sudo sqlite3 "$base_dir/$db_file" "SELECT path FROM $table_name WHERE path = '$initial_path_save';")
        if [ -z "$existing_path" ]; then
            # Path doesn't exist, clear old data and insert
            result=$(sudo sqlite3 "$base_dir/$db_file" "DELETE FROM $table_name;")
            checkSuccess "Clearing old path data"
            result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (path) VALUES ('$initial_path_save');")
            checkSuccess "Adding $initial_path_save to the $table_name table."
        fi
    fi
}

databasePortInsert()
{
    local app_name="$1"
    local portdata="$2"

    # Split the portdata into port and type
    IFS='/' read -r port type <<< "$portdata"

    if [ -f "$base_dir/$db_file" ] && [ -n "$app_name" ]; then
        table_name=ports
        # Check if already exists in the database
        existing_portdata=$(sudo sqlite3 "$base_dir/$db_file" "SELECT port FROM $table_name WHERE name = '$app_name' AND port = '$port' AND type = '$type';")
        if [ -z "$existing_portdata" ]; then
            result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (name, port, type) VALUES ('$app_name', '$port', '$type');")
            checkSuccess "Adding port $port and type $type for $app_name to the $table_name table."
        fi
    fi
}

databaseBackupInsert()
{
    local app_name="$1"
    local table_name=backups
    result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table."    
}

databaseRestoreInsert()
{
    local app_name="$1"
    local table_name=restores
    result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table."
}

databaseMigrateInsert()
{
    local app_name="$1"
    local table_name=migrations
    result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table." 
}

databaseSSHInsert()
{
    local app_name="$1"
    local table_name=ssh
    result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (ip, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
    checkSuccess "Adding $app_name to the $table_name table." 
}

databaseSSHKeysInsert()
{
    local key_filename="$1"
    local key_file=$(basename "$key_filename")
    local table_name=ssh_keys
    local key_in_db=$(sudo sqlite3 "$base_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE name = '$key_file';")

    if [ "$key_in_db" -eq 0 ]; then
        result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$key_file', '$current_date', '$current_time');")
        checkSuccess "Adding $key_file to the $table_name table."
    else
        result=$(sudo sqlite3 "$base_dir/$db_file" "UPDATE $table_name SET name = '$key_file', date = '$current_date', time = '$current_time' WHERE name = '$key_file';")
        checkSuccess "$key_file already added to the $table_name table. Updating date/time."
    fi
}

databaseCronJobsInsert()
{
    local app_name="$1"
    local table_name=cron_jobs
    local key_in_db=$(sudo sqlite3 "$base_dir/$db_file" "SELECT COUNT(*) FROM $table_name WHERE name = '$app_name';")

    if [ "$key_in_db" != "" ]; then
        if [ "$key_in_db" -eq 0 ]; then
            result=$(sudo sqlite3 "$base_dir/$db_file" "INSERT INTO $table_name (name, date, time) VALUES ('$app_name', '$current_date', '$current_time');")
            checkSuccess "Adding $app_name to the $table_name table." 
        else
            result=$(sudo sqlite3 "$base_dir/$db_file" "UPDATE $table_name SET name = '$app_name', date = '$current_date', time = '$current_time' WHERE name = '$app_name';")
            checkSuccess "$app_name already added to the $table_name table. Updating date/time." 
        fi
        #isNotice "app_name is empty, unable to insert"
    fi
}

databaseRemoveFile()
{
	if [[ "$tooldeletedb" == [yY] ]]; then
        result=$(sudo -u $easydockeruser rm $base_dir/$db_file)
        checkSuccess "Removing $db_file file"
    fi
}