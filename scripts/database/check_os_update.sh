#!/bin/bash

# Function to check is we should run the update
checkIfOSUpdateShouldRun() 
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
