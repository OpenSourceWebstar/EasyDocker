#!/bin/bash

appOwnCloudSetupConfig()
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
    2 => '$public_ip_v4',
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
