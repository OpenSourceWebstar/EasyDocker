#!/bin/bash

installSwapfile()
{
    if [[ "$CFG_REQUIREMENT_SWAPFILE" == "true" ]]; then
        if [ ! -f "$swap_file" ]; then
            echo ""
            echo "############################################"
            echo "######       Increasing Swapfile      ######"
            echo "############################################"
            echo ""
            ISSWAP=$( (sudo -u $easydockeruser swapoff /swapfile) 2>&1 )
            if [[ "$ISSWAP" != *"No such file or directory"* ]]; then
                result=$(sudo -u $easydockeruser swapoff /swapfile)
                isSuccessful "Turning off /swapfile (if needed)"
            fi

            result=$(sudo -u $easydockeruser fallocate -l $CFG_SWAPFILE_SIZE /swapfile)
            checkSuccess "Allocating $CFG_SWAPFILE_SIZE to the /swapfile"
            
            result=$(sudo -u $easydockeruser chmod 0600 /swapfile)
            checkSuccess "Adding permissions to the /swapfile"

            result=$(sudo -u $easydockeruser mkswap /swapfile)
            checkSuccess "Swapping to the new /swapfile"

            result=$(sudo -u $easydockeruser swapon /swapfile)
            checkSuccess "Enabling the new /swapfile"
        fi
    fi
}

installSSLCertificate()
{
	if [[ "$CFG_REQUIREMENT_SSLCERTS" == "true" ]]; then
        if [[ "$SkipSSLInstall" != "true" ]]; then
            echo ""
            echo "############################################"
            echo "######     Install SSL Certificate    ######"
            echo "############################################"
            echo ""

            # Read the config file and extract domain values
            domains=()
            for domain_num in {1..9}; do
                domain="CFG_DOMAIN_$domain_num"
                domain_value=$(grep "^$domain=" "$configs_dir$config_file_general" | cut -d '=' -f 2 | tr -d '[:space:]')
                
                if [ -n "$domain_value" ]; then
                    domains+=("$domain_value")
                fi
            done

            # Function to generate SSL certificate for a given domain
            generateSSLCertificate() {
                local domain_value="$1"
                result=$(cd $ssl_dir && openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/CN=$domain_value" -keyout "$ssl_dir/$domain_value.key" -out "$ssl_dir/$domain_value.crt" >/dev/null 2>&1)
                checkSuccess "SSL Generation for $domain_value"
            }

            # Generate SSL certificates for each domain
            for domain_value in "${domains[@]}"; do
                isNotice "Creating SSL certificate for $domain_value..."
                generateSSLCertificate "$domain_value"
            done

            # Check if generated certificates match the ones in the SSL folder
            isNotice "Checking SSL certificates..."
            for domain_value in "${domains[@]}"; do
                if cmp -s "$ssl_dir/$domain_value.key" "$ssl_dir/$domain_value.crt"; then
                    isNotice "Certificate for $domain_value does not match in the SSL folder."

                    isQuestion "Do you want to regenerate the SSL certificate for $domain_value? (y/n): "
                    read -rp "" SSLRegenchoice

                    if [ "$SSLRegenchoice" == "y" ]; then
                        echo "Regenerating SSL certificate for $domain_value..."
                        generateSSLCertificate "$domain_value"
                    else
                        echo "Skipping regeneration for $domain_value."
                    fi  
                else
                    isSuccessful "Certificate for $domain_value matches in the SSL folder."
                fi
            done

            sslcertchoice=n
        fi
    fi
}

installCrontab()
{
    if [[ "$CFG_REQUIREMENT_CRONTAB" == "true" ]]; then
        echo ""
        echo "############################################"
        echo "######       Crontab Install          ######"
        echo "############################################"
        echo ""

        # Check to see if already installed
        if [[ "$ISCRON" == *"command not found"* ]]; then
            isNotice "Crontab is not installed, setting up now."
            result=$(sudo apt update)
            checkSuccess "Updating apt for post installation"
            result=$(sudo apt install cron -y)
            isSuccessful "Installing crontab application"
            result=$(sudo -u $easydockeruser crontab -l)
            isSuccessful "Enabling crontab on the system"
        fi

        search_line="# cron is set up for $easydockeruser"
        cron_output=$(sudo -u $easydockeruser crontab -l 2>/dev/null)

        if [[ ! $cron_output == *"$search_line"* ]]; then
            result=$( (sudo -u $easydockeruser crontab -l 2>/dev/null; echo "# cron is set up for $easydockeruser") | sudo -u $easydockeruser crontab - )
            checkSuccess "Setting up crontab for $easydockeruser user"
        fi

        export VISUAL=nano
        export EDITOR=nano

        installCrontabSSHScan;
    fi
}

# Function to remove all crontab data
deleteCrontab() 
{
    echo "" | sudo -u $easydockeruser crontab -
    echo "All crontab data has been deleted."
}

installBackupCrontabApp()
{
    local name=$1

    if ! sudo -u $easydockeruser crontab -l | grep -q "$name"; then
        isNotice "Automatic Backups for $name are not set up."
        while true; do
            isQuestion "Do you want to set up automatic $name backups (y/n): "
            read -rp "" setupcrontab
            if [[ "$setupcrontab" =~ ^[yYnN]$ ]]; then
                break
            fi
            isNotice "Please provide a valid input (y/n)."
        done
        if [[ "$setupcrontab" =~ ^[yY]$ ]]; then

            installSetupCrontab $name
            if [[ "$name" != "full" ]]; then
                databaseCronJobsInsert $name
                installSetupCrontabTiming $name
            fi
        fi
    fi
}

installCrontabSSHScan() 
{
    local marker="# CRONTAB SSHSCAN"
    local cron_job="*/5 * * * * cd /docker/install/ && chmod 0775 crontab.sh && ./crontab.sh sshscan"

    # Check if the cron job does not exist in the user's crontab
    if ! sudo -u $easydockeruser crontab -l | grep -qF "$cron_job"; then
        result=$( (sudo -u $easydockeruser crontab -l 2>/dev/null; echo "$marker") | sudo -u $easydockeruser crontab - )
        checkSuccess "Add the SSHScan marker to the crontab"
        result=$( (sudo -u $easydockeruser crontab -l 2>/dev/null; echo "$cron_job") | sudo -u $easydockeruser crontab - )
        checkSuccess "Adding SSH Scaning to the Crontab"
    else
        isNotice "Cron job for SSH scan already exists. Skipping insertion."
    fi
}

# Function to set up the backup entry in crontab
installSetupCrontab() {
    local entry_name=$1

    # Check to see if already instealled
    if ! sudo -u $easydockeruser crontab -l | grep -q "cron is set up for $easydockeruser"; then
        isError "Crontab is not setup"
        return
    fi

    if [ "$entry_name" = "full" ]; then
        local crontab_entry="$CFG_BACKUP_CRONTAB_FULL cd /docker/install/ && chmod 0775 crontab.sh && ./crontab.sh $entry_name"
    else
        local crontab_entry="$CFG_BACKUP_CRONTAB_APP cd /docker/install/ && chmod 0775 crontab.sh && ./crontab.sh $entry_name"
    fi

    local apps_comment="# CRONTAB BACKUP APPS"
    local full_comment="# CRONTAB BACKUP FULL"
    local existing_crontab=$(sudo -u $easydockeruser crontab -l 2>/dev/null)
    

    if ! echo "$existing_crontab" | grep -q "$full_comment"; then
        existing_crontab=$(echo -e "$existing_crontab\n$full_comment")
        checkSuccess "Check if the full comment exists in the crontab"
    fi

    if [ "$entry_name" = "full" ]; then
        existing_crontab=$(echo "$existing_crontab" | sed "/$full_comment/a\\
$crontab_entry")
        checkSuccess "Add the new backup entry to the existing crontab"
    else
        # Check if the apps comment exists in the crontab
        if ! echo "$existing_crontab" | grep -q "$apps_comment"; then
            existing_crontab=$(echo -e "$existing_crontab\n$apps_comment")
            checkSuccess "Insert the full entry after the full comment"
        fi
        existing_crontab=$(echo "$existing_crontab" | sed "/$apps_comment/a\\
$crontab_entry")
        checkSuccess "Insert the non-full entry after the apps comment"
    fi

    result=$(echo "$existing_crontab" | sudo -u $easydockeruser crontab -)
    checkSuccess "Set the updated crontab"
    
    crontab_full_value=$(echo "$CFG_BACKUP_CRONTAB_APP" | cut -d' ' -f2)
    if [ "$entry_name" = "full" ]; then
        isSuccessful "$entry_name will be backed up every day at $crontab_full_value:am"
    fi
}

# Function to update a specific line in the crontab
installSetupCrontabTiming() {
    local entry_name=$1
    ISCRON=$( (sudo -u $easydockeruser crontab -l) 2>&1 )

    # Check to see if installed
    if [[ "$ISCRON" == *"command not found"* ]]; then
        isError "Cron is not installed."
        return 1
    fi

    # Check to see if already setup
    if ! sudo -u $easydockeruser crontab -l | grep -q "cron is set up for $easydockeruser"; then
        isError "Crontab is not setup"
        return 1
    fi

    # Check if sqlite3 is available
    if ! command -v sqlite3 &> /dev/null; then
      isNotice "sqlite3 command not found. Make sure it's installed."
      return 1
    fi

    # Ensure the database file exists
    if [ ! -f "$base_dir/$db_file" ]; then
      isError "Database file not found: $base_dir/$db_file"
      return
    fi

    # Step 1: Retrieve the necessary information from the database
    db_entry=$(sqlite3 "$base_dir/$db_file" "SELECT id, name FROM cron_jobs WHERE name='$entry_name';")
    IFS='|' read -r id name <<< "$db_entry"

    # Check if the entry exists in the database
    if [[ -z "$id" ]]; then
        isError "Entry '$entry_name' not found in the database."
    fi

    # Calculate the new minute value based on the ID
    new_minute_value=$((id * $CFG_BACKUP_CRONTAB_APP_INTERVAL))

    # Step 2: Locate the existing crontab entry in the crontab file
    crontab_entry_to_update=$(sudo -u $easydockeruser crontab -l | grep "$entry_name")

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

    result=$(sudo -u $easydockeruser crontab -l | grep -v "$entry_name" | sudo -u $easydockeruser crontab - )
    checkSuccess "Remove the existing crontab entry"
    result=$( (sudo -u $easydockeruser crontab -l; echo "$updated_crontab_entry") | sudo -u $easydockeruser crontab - )
    checkSuccess "Add the updated crontab entry"

    isSuccessful "Crontab entry for '$entry_name' updated successfully."
    isSuccessful "$entry_name will be backed up every day at $crontab_app_value:${new_minute_value}am"
}

installSQLiteDatabase()
{
	if [[ $CFG_REQUIREMENT_DATABASE == "true" ]]; then
        # Safeguard loading
        if [ ! -e "$base_dir/$db_file" ]; then
            if command -v sqlite3 &> /dev/null; then
                echo ""
                echo "##########################################"
                echo "###     Setup SQLite Database"
                echo "##########################################"
                echo ""

                # Create SQLite database file
                if [ ! -e "$base_dir/$db_file" ]; then
                    result=$(createTouch $base_dir/$db_file)
                    checkSuccess "Creating SQLite $db_file file"
                fi

                setup_table_name=path
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (path TEXT );")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=sysupdate
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=apps
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                # status = 1 = installed, 0 uninstalled
                # TODO - Add should backup column
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (name TEXT UNIQUE, status DATE, install_date DATE, uninstall_date DATE);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=backups
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=restores
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=migrations
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=ssh
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, ip TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=ssh_keys
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (name TEXT UNIQUE, hash TEXT, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                setup_table_name=cron_jobs
                if ! sqlite3 "$base_dir/$db_file" ".tables" | grep -q "\b$setup_table_name\b"; then
                # Table info here
                result=$(sqlite3 $base_dir/$db_file "CREATE TABLE IF NOT EXISTS $setup_table_name (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, date DATE, time TIME);")
                checkSuccess "Creating $setup_table_name table"
                fi

                # Get the list of table names from the database
                sql_table_names=$(sqlite3 "$base_dir/$db_file" ".tables")

                # Loop through the table names and print the desired text
                for sql_table_name in $sql_table_names; do
                    isSuccessful "Table $sql_table_name found in database."
                done
            fi
        fi
    fi
}