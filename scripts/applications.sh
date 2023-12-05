#!/bin/bash

updateApplicationSpecifics()
{
    local app_name="$1"

    # Initialize setup.
    setupInstallVariables $app_name;

    if [[ $app_name == "adguard" ]] || [[ $app_name == "pihole" ]]; then
        updateDNS $app_name install;
    fi

    if [[ $app_name == "owncloud" ]]; then
        ownCloudSetupConfig;
        local shouldrestart=true
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

    local domains=("$ip_setup" "$host_setup")
    local owncloud_config="$containers_dir$app_name/files/config/config.php"
    local temp_dir="/tmp/owncloud_setup_temp"  # Use a temporary directory
    local owncloud_config_tmp="$temp_dir/config.php.tmp"

    local owncloud_timeout=60
    local owncloud_wait_time=5  # seconds

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

    # Copy the original config.php to the temporary file
    result=$(sudo cp -p "$owncloud_config" "$owncloud_config_tmp")
    checkSuccess "Copy the original config.php to the temporary file"

    # Use awk to delete lines for 'trusted_domains' from the temporary file
    result=$(sudo awk '/'"'trusted_domains'"'/,/\),/' "$owncloud_config_tmp" > "$owncloud_config_tmp")
    checkSuccess "Use awk to delete lines for 'trusted_domains' from the temporary file"

    # Use awk to get the line number containing ");" from the temporary file
    local line_number=$(sudo awk '/);/{print NR}' "$owncloud_config_tmp")
    # Insert the new lines above the line with ");" in the temporary file
    sudo sed -i "${line_number}i\\
        'trusted_domains' => array(\\
            0 => '$ip_address',\\
            1 => '$host',\\
        ),\\
    );" "$owncloud_config_tmp"

    # Use sed to replace the line in the original file
    result=$(sudo sed -E -i "s/'overwrite.cli.url' => 'http:\/\/[0-9.:]+'/'overwrite.cli.url' => 'http:\/\/$ip_setup:$usedport\/'/" "$owncloud_config_tmp")
    checkSuccess "Updated the internal CLI config IP & Port"

    # Move the modified temporary file back to the original location
    result=$(sudo mv "$owncloud_config_tmp" "$owncloud_config")
    checkSuccess "Overwrite the original config.php with the updated content"

    # Remove the temporary directory
    result=$(sudo rm -rf "$temp_dir")
    checkSuccess "Clean up temporary directory"

    result=$(sudo chmod --reference="$containers_dir$app_name/files/config/objectstore.config.php" "$owncloud_config")
    checkSuccess "Updating config permissions to associated permissions"
}

dashyUpdateConf() 
{
    # Hardcoded path to Dashy's conf.yml file
    local conf_file="${containers_dir}dashy/etc/conf.yml"
    local status=$(checkAppInstalled "dashy" "docker")

    # Check if Dashy app is installed
    if [ "$status" == "installed" ]; then
        echo ""
        echo "#####################################"
        echo "###    Dashy Config Generation    ###"
        echo "#####################################"
        echo ""

        if [ -f "$conf_file" ]; then
            local result=$(sudo rm -rf "$conf_file")
            checkSuccess "Removed old Dashy conf.yml for new generation"
        fi

        # Copy the default dashy conf.yml configuration file
        local result=$(copyResource "dashy" "conf.yml" "etc")
        checkSuccess "Copy default dashy conf.yml configuration file"

        local original_md5=$(md5sum "$conf_file")

        # Initialize changes_made flag as false
        local changes_made=false

        # Function to uncomment lines using sed based on line numbers under the pattern
        uncomment_lines() 
        {
            local app_name="$1"
            local pattern="#### app $app_name"
            local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

            if [ -n "$start_line" ]; then
                # Uncomment lines under the app section based on line numbers
                sudo sed -i "$((start_line+1))s/#- title/- title/" "$conf_file"
                sudo sed -i "$((start_line+2))s/#  description/  description/" "$conf_file"
                sudo sed -i "$((start_line+3))s/#  icon/  icon/" "$conf_file"
                sudo sed -i "$((start_line+4))s/#  url/  url/" "$conf_file"
                sudo sed -i "$((start_line+5))s/#  statusCheck/  statusCheck/" "$conf_file"
                sudo sed -i "$((start_line+6))s/#  target/  target/" "$conf_file"
            fi
        }

        # Function to uncomment category lines using sed based on line numbers under the pattern
        uncomment_category_lines() 
        {
            local category_name="$1"
            local pattern="#### category $category_name"
            local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

            if [ -n "$start_line" ]; then
                # Uncomment lines under the category section based on line numbers
                sudo sed -i "$((start_line+1))s/^#- name/- name/" "$conf_file"
                sudo sed -i "$((start_line+2))s/^#  icon/  icon/" "$conf_file"
                sudo sed -i "$((start_line+3))s/^#  items/  items/" "$conf_file"
            fi
        }

        # Loop through immediate subdirectories of $containers_dir
        for app_dir in "$containers_dir"/*/; do
            if [ -d "$app_dir" ]; then
                local app_name=$(basename "$app_dir")
                local app_config_file="$app_dir$app_name.sh"
                if [ -f "$app_config_file" ]; then
                    local category_info=$(grep -Po '(?<=# Category : ).*' "$app_config_file")
                    if [ -n "$category_info" ]; then
                        uncomment_lines "$app_name"
                    fi
                fi
            fi
        done

        # Collect all installed app paths
        installed_app_paths=()
        while IFS= read -r -d $'\0' app_name_dir; do
            local app_name_path="$app_name_dir"
            local installed_app_paths+=("$app_name_path")
        done < <(sudo find "$containers_dir" -mindepth 2 -maxdepth 2 -type d -print0)

        # Get unique category names related to installed apps
        installed_categories=()
        for app_path in "${installed_app_paths[@]}"; do
            if [ -d "$app_path" ]; then
                local app_config_file="$app_path/$(basename "$app_path").sh"
                if [ -f "$app_config_file" ]; then
                    local category_info=$(grep -Po '(?<=# Category : ).*' "$app_config_file")
                    if [ -n "$category_info" ]; then
                        # Get the category name from the app's folder
                        local category_name=$(basename "$(dirname "$app_path")")
                        # Add the category to the list if not already present
                        if [[ ! " ${installed_categories[@]} " =~ " $category_name " ]]; then
                            local installed_categories+=("$category_name")
                        fi
                    fi
                fi
            fi
        done

        # Call the uncomment_category_lines function for each installed category
        for category_name in "${installed_categories[@]}"; do
            uncomment_category_lines "$category_name"
        done

        local updated_md5=$(md5sum "$conf_file")

        # Check if changes were made to the file
        if [ "$original_md5" != "$updated_md5" ]; then
            isNotice "Changes made to dashy config file...restarting dashy..."
            runCommandForDockerInstallUser "docker restart dashy" > /dev/null 2>&1
            isSuccessful "Restarted dashy docker container (if running)"
        else
            isSuccessful "No new changes made to the dashy config file."
        fi
    fi
}
