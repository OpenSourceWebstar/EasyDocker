#!/bin/bash

# Function to update a specific line in the crontab
installSetupCrontabTiming() 
{
    local entry_name=$1
    ISCRON=$( (sudo -u $sudo_user_name crontab -l) 2>&1 )

    # Check to see if installed
    if [[ "$ISCRON" == *"command not found"* ]]; then
        isError "Cron is not installed."
        return 1
    fi

    # Check to see if already setup
    if ! sudo -u $sudo_user_name crontab -l 2>/dev/null | grep -q "cron is set up for $sudo_user_name"; then
        isError "Crontab is not setup"
        return 1
    fi

    # Check if sqlite3 is available
    if ! command -v sqlite3 &> /dev/null; then
      isNotice "sqlite3 command not found. Make sure it's installed."
      return 1
    fi

    # Ensure the database file exists
    if [ ! -f "$docker_dir/$db_file" ]; then
      isNotice "Database file not found: $docker_dir/$db_file"
      return
    fi

    # Step 1: Retrieve the necessary information from the database
    db_entry=$(sqlite3 "$docker_dir/$db_file" "SELECT id, name FROM cron_jobs WHERE name='$entry_name';")
    IFS='|' read -r id name <<< "$db_entry"

    # Check if the entry exists in the database
    if [[ -z "$id" ]]; then
        isNotice "Entry '$entry_name' not found in the database."
    fi

    # Calculate the new minute value based on the ID
    new_minute_value=$((id * $CFG_BACKUP_CRONTAB_APP_INTERVAL))

    # Step 2: Locate the existing crontab entry in the crontab file
    crontab_entry_to_update=$(sudo -u $sudo_user_name crontab -l | grep "$entry_name")

    # Check if the entry exists in the crontab
    if [[ -z "$crontab_entry_to_update" ]]; then
        isError "Entry '$entry_name' not found in the crontab."
    fi

    # Extract the existing minute value from the current crontab entry
    current_minute_value=$(echo "$crontab_entry_to_update" | awk '{print $1}')

    # Step 3: Update the minute value in the identified crontab entry
    updated_crontab_entry="${crontab_entry_to_update/$current_minute_value/$new_minute_value}"

    # Assuming CFG_BACKUP_CRONTAB_APP is set to "0 5 * * *"
    crontab_app_value=$(echo "$CFG_BACKUP_CRONTAB_APP" | cut -d' ' -f2)

    local result=$(sudo -u $sudo_user_name crontab -l | grep -v "$entry_name" | sudo -u $sudo_user_name crontab - )
    checkSuccess "Remove the existing crontab entry"
    local result=$( (sudo -u $sudo_user_name crontab -l; echo "$updated_crontab_entry") | sudo -u $sudo_user_name crontab - )
    checkSuccess "Add the updated crontab entry"

    isSuccessful "Crontab entry for '$entry_name' updated successfully."
    isSuccessful "$entry_name will be backed up every day at $crontab_app_value:${new_minute_value}am"
}
