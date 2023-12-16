#!/bin/bash

updateApplicationSpecifics()
{
    local app_name="$1"

    # Initialize setup.
    setupInstallVariables $app_name;

    if [[ $app_name == "adguard" ]] || [[ $app_name == "pihole" ]]; then
        updateDNS $app_name install;
    fi

    if [[ $shouldrestart == "true" ]]; then
        dockerDownUp $app_name;
    fi

    isSuccessful "All application specific updates have been completed."
}

ownCloudSetupConfig()
{
    isNotice "ownCloud is currently being set up, please wait..."
    isNotice "This may take a few minutes..."
    echo ""
    # Run the health check loop with timings
    dockerCheckContainerHealthLoop "owncloud" 180 15

    # If container is healthy
    if dockerCheckContainerHealth "owncloud"; then
        isSuccessful "OwnCloud container is healthy, continuing with the install."
        local app_name="owncloud"
        local tmp_folder="/tmp/owncloud_setup_temp"
        local owncloud_config_folder="$containers_dir$app_name/files/config"
        local owncloud_config="${owncloud_config_folder}/config.php"
        local owncloud_timeout=60
        local owncloud_wait_time=5  # seconds

        # Remove the temporary folder in /tmp
        result=$(sudo rm -rf "$owncloud_config")
        checkSuccess "Removed default config.php"

        # Check when owncloud is setup.
        # Loop to check for the existence of the file every second
        local owncloud_counter=0
        while [ ! -f "$containers_dir$app_name/files/config/objectstore.config.php" ]; do
            if [ "$owncloud_counter" -ge "$owncloud_timeout" ]; then
                isNotice "File not found after $owncloud_timeout seconds. Exiting..."
                break
            fi
            isNotice "Waiting 5 seconds for the objectstore.config.php to appear..."
            sleep $owncloud_wait_time
            local owncloud_counter=$((owncloud_counter + 1))
        done
        
        # Loop to check for the existence of the file every second
        local owncloud_counter=0
        # File does not exist or is 0 KB
        while [ ! -f "$containers_dir$app_name/files/config/config.php" ] || [ $(stat -c %s "$containers_dir$app_name/files/config/config.php") -eq 0 ]; do
            if [ "$owncloud_counter" -ge "$owncloud_timeout" ]; then
                isNotice "File not found after $owncloud_timeout seconds. Exiting..."
                break
            fi
            isNotice "Waiting 5 seconds for the config.php to appear..."
            sleep $owncloud_wait_time
            local owncloud_counter=$((owncloud_counter + 1))
        done
        
        # Backups and Creation of config files
        # Copy the original config.php to the temporary file
        # Create a temporary folder in /tmp
        result=$(sudo mkdir -p "$tmp_folder")
        checkSuccess "Created temporary folder: $tmp_folder"
        
        # Backups and Creation of config files
        # Copy the original config.php to the temporary file in /tmp
        result=$(sudo cp "$owncloud_config" "$tmp_folder/config.php.tmp")
        checkSuccess "Copy the original config.php contents to the temporary file"

        result=$(sudo cp "$owncloud_config" "$owncloud_config_folder/config.php.backup")
        checkSuccess "Backing up the original config.php file"
        
        local result=$(sudo chmod -R 777 "$tmp_folder")
        checkSuccess "Set permissions to for temp folder & files."
        
        local result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$tmp_folder")
        checkSuccess "Updating ownership on temp folder to $CFG_DOCKER_INSTALL_USER"
        
        # Create another temporary file for awk output
        local tmp_awk_output="$tmp_folder/config_awk_output.tmp"

        # Use awk to delete lines for 'trusted_domains' from the temporary file
        result=$(sudo awk '/'"'trusted_domains'"'/,/\),/{next} {print}' "$tmp_folder/config.php.tmp" > "$tmp_awk_output")
        checkSuccess "Use awk to delete lines for 'trusted_domains' from the temporary file"
        
        # Remove the line containing 'overwrite.cli.url'
        result=$(sudo sed -i '/overwrite\.cli\.url/d' "$tmp_awk_output")
        checkSuccess "Remove line containing 'overwrite.cli.url'"

        # Remove the existing ');' from the end of the file
        result=$(sudo sed -i '$s/);//' "$tmp_awk_output")
        checkSuccess "Remove ');' from the end of the file"
        
        # Remove empty lines from the temporary file
        result=$(sudo sed -i '/^ *$/d' "$tmp_awk_output")
        checkSuccess "Remove empty lines from the temporary file"

if [[ $public == "true" ]]; then
# Add new lines at the end of the file
sudo tee -a "$tmp_awk_output" > /dev/null <<EOL
'overwrite.cli.url' => 'https://$host_setup/',
'Overwriteprotocol' => 'https',
'trusted_domains' =>
array(
    0 => '$host_setup',
    1 => '$ip_setup',
    2 => '$public_ip',
),
);

EOL
checkSuccess "Add overwrite and trusted_domain (public) lines to the config"
elif [[ $public == "false" ]]; then
# Add new lines at the end of the file
sudo tee -a "$tmp_awk_output" > /dev/null <<EOL
'trusted_domains' =>
array(
    0 => '$ip_setup',
),
);

EOL
checkSuccess "Add overwrite and trusted_domain (public) lines to the config"
fi

        # Update permissions
        # Move the modified temporary file back to the original location
        result=$(sudo mv "$tmp_awk_output" "$owncloud_config")
        checkSuccess "Overwrite the original config.php with the updated content"

        result=$(sudo chown 165568:$CFG_DOCKER_INSTALL_USER $owncloud_config)
        checkSuccess "Update permissions of ownCloud config to reflect container needs."
        
        # Remove the temporary folder in /tmp
        result=$(sudo rm -rf "$tmp_folder")
        checkSuccess "Removed temporary folder: $tmp_folder"
    else
        isError "Container is not healthy. Setup seems to have failed."
        return
    fi

}

dashyUpdateConf() 
{
    local conf_file="${containers_dir}dashy/etc/conf.yml"
    local status=$(checkAppInstalled "dashy" "docker")

    setupAppURL() 
    {
        local app_name="$1"
        setupBasicAppVariable $app_name;

        local dashy_app_url=""
        if [ "$app_public" == "true" ]; then
            dashy_app_url="$app_host_setup"
        else
            dashy_app_url="$app_ip_setup:$app_usedport1"
        fi
        echo "$dashy_app_url"
    }

    # Function to uncomment app lines using sed based on line numbers under the pattern
    uncommentApp() 
    {
        local app_name="$1"
        local pattern="#### app $app_name"
        local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

        if [ -n "$start_line" ]; then
            # Uncomment lines under the app section based on line numbers
            sudo sed -i "$((start_line+1))s/#- title/- title/" "$conf_file"
            sudo sed -i "$((start_line+2))s/#  description/  description/" "$conf_file"
            sudo sed -i "$((start_line+3))s/#  icon/  icon/" "$conf_file"
            sudo sed -i "$((start_line+4))s|#  url: http://APPADDRESSHERE/|  url: http://$(setupAppURL $app_name)/|" "$conf_file"
            sudo sed -i "$((start_line+5))s/#  statusCheck/  statusCheck/" "$conf_file"
            sudo sed -i "$((start_line+6))s/#  target/  target/" "$conf_file"
        fi
    }

    # Function to uncomment category lines using sed based on line numbers under the pattern
    uncommentCategoryForApp() 
    {
        local app_name="$1"
        local pattern="#### category $app_name"
        local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

        if [ -n "$start_line" ]; then
            # Uncomment lines under the category section based on line numbers
            sudo sed -i "$((start_line+1))s/^#- name/- name/" "$conf_file"
            sudo sed -i "$((start_line+2))s/^#  icon/  icon/" "$conf_file"
            sudo sed -i "$((start_line+3))s/^#  items/  items/" "$conf_file"
        fi
    }

    # Array to keep track of uncommented categories
    local uncommented_categories=()

    if [ "$status" == "installed" ]; then
        echo ""
        echo "#####################################"
        echo "###    Dashy Config Generation    ###"
        echo "#####################################"
        echo ""

        local original_md5=$(md5sum "$conf_file")

        if [ -f "$conf_file" ]; then
            sudo rm -rf "$conf_file"
            checkSuccess "Removed old Dashy conf.yml for new generation"
        fi

        copyResource "dashy" "conf.yml" "etc"
        checkSuccess "Copy default dashy conf.yml configuration file"

        sudo sed -i "s/INSTALLNAMEHERE/$CFG_INSTALL_NAME/" "$conf_file"

        for app_dir in "${containers_dir}"/*/; do
            if [ -d "$app_dir" ]; then
                local app_name=$(basename "$app_dir")
                local app_config_file="${install_containers_dir}/${app_name}/${app_name}.sh"

                if [ -f "$app_config_file" ]; then
                    local category_info=$(awk -F ': ' '/# Category :/{print $2}' "$app_config_file")

                    if [ -n "$category_info" ] && ! [[ " ${uncommented_categories[@]} " =~ " $category_info " ]]; then
                        uncommentCategoryForApp "$category_info"
                        uncommented_categories+=("$category_info")
                    fi

                    uncommentApp "$app_name"
                fi
            fi
        done

        local updated_md5=$(md5sum "$conf_file")

        if [ "$original_md5" != "$updated_md5" ]; then
            isNotice "Changes made to dashy config file...restarting dashy..."
            runCommandForDockerInstallUser "docker restart dashy" > /dev/null 2>&1
            isSuccessful "Restarted dashy docker container (if running)"
        else
            isSuccessful "No new changes made to the dashy config file."
        fi
    fi
}

invidiousResetUserPassword()
{
    while true; do
        isQuestion "Please enter the username or email which you would like to password reset (enter 'x' to exit): "
        read -p "" invidiousresetconfirm
        if [[ "$invidiousresetconfirm" == [xX] ]]; then
            isNotice "Exiting..."
            break
        fi
        if [[ "$invidiousresetconfirm" != [xX] ]]; then
            # The hash for 'password'
            local bcrypt_hash="$2b$10$xN4J3LJafAv91X29KJJREeg7RfDcoKmleNm2LIfF0j5IoKuHXVA4O"
            # Debugging output
            echo "Debugging: email=$email, database_name=$database_name, bcrypt_hash=$bcrypt_hash"

            # Construct and print the SQL query
            sql_query="UPDATE users SET password = E'$bcrypt_hash' WHERE email = E'$email';"
            echo "Debugging: SQL Query: $sql_query"

            # Execute the command
            runCommandForDockerInstallUser "docker exec invidious-db /bin/bash -c \"psql -U kemal -d $database_name <<EOF
            $sql_query
            EOF\" && exit"
            isSuccessful "If the user $invidiousresetconfirm exists, the new password will be 'password'"
            sleep 5;
            break
        fi
    done
}

mattermostResetUserPassword() 
{
    local mattermostusername
    local mattermostpassword

    while true; do
        isQuestion "Please enter the username or email which you would like to password reset (enter 'x' to exit): "
        read -p "" mattermostusername
        if [[ "$mattermostusername" == [xX] ]]; then
            isNotice "Exiting..."
            endStart;
        fi
        break
    done

    while true; do
        isQuestion "Please enter the password you would like to use (enter 'x' to exit): "
        read -p "" mattermostpassword
        if [[ "$mattermostpassword" == [xX] ]]; then
            isNotice "Exiting..."
            endStart;
        fi
        break
    done

    if [[ "$mattermostusername" != [xX] && "$mattermostpassword" != [xX] ]]; then
        local config_json="$containers_dir/mattermost/volumes/app/mattermost/config/config.json"
        
        # Enable local mode
        result=$(sudo sed -i "s|\"EnableLocalMode\": false|\"EnableLocalMode\": true|" "$config_json")
        checkSuccess "EnableLocalMode set to true for password update."
        restartApp mattermost;
        
        isNotice "Waiting 10 seconds for mattermost to load the local socket"
        sleep 10
        # Update Password
        runCommandForDockerInstallUser "docker exec mattermost /bin/bash -c \"mmctl --local user change-password $mattermostusername --password $mattermostpassword\" && exit"
        
        # Disable local mode
        result=$(sudo sed -i "s|\"EnableLocalMode\": true|\"EnableLocalMode\": false|" "$config_json")
        checkSuccess "EnableLocalMode set to false for password update."
        restartApp mattermost;

        isSuccessful "Password for username $mattermostusername has been changed to $mattermostpassword if the user exists."
        sleep 5
    fi
}
