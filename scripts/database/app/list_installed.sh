#!/bin/bash

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
