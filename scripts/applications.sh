#!/bin/bash

updateApplicationSpecifics()
{
    local app_name="$1"

    if [[ $app_name == "adguard" ]] || [[ $app_name == "pihole" ]]; then
        updateDNS;
    fi

    if [[ $app_name == "owncloud" ]]; then
        ownCloudSetupConfig;
        local shouldrestart=true
    fi

    if [[ $app_name == "dashy" ]]; then
        dashyUpdateConf;
    fi

    if [[ $shouldrestart == "true" ]]; then
        dockerDownUp $app_name;
    fi
}

ownCloudSetupConfig()
{
    local domains=("$ip_setup" "$host_setup")
    local owncloud_config="$containers_dir$app_name/files/config/config.php"
    local owncloud_config_tmp="$containers_dir$app_name/files/config/config.php.tmp"

    result=$(sudo cp -p "$owncloud_config" "$owncloud_config_tmp")
    checkSuccess "Copy the original config.php to the temporary file"

    local found_trusted_domains=false

    # Read the original config.php file
    while IFS= read -r line; do
        # Check if the line contains 'trusted_domains'
        if [[ $line == *"trusted_domains"* ]]; then
            local found_trusted_domains=true
        fi

        # If 'trusted_domains' is found, add the new data
        if [ "$found_trusted_domains" == true ]; then
            echo "  'trusted_domains' => " | sudo tee -a "$owncloud_config_tmp"
            echo "  array (" | sudo tee -a "$owncloud_config_tmp"
            echo "    0 => '$ip_address'," | sudo tee -a "$owncloud_config_tmp"
            echo "    1 => '$host'," | sudo tee -a "$owncloud_config_tmp"
            echo "  )," | sudo tee -a "$owncloud_config_tmp"
            echo ");" | sudo tee -a "$owncloud_config_tmp"

            # Reset the flag
            local found_trusted_domains=false
        fi

        # Add the current line to the temporary file
        echo "$line" | sudo tee -a "$owncloud_config_tmp"
    done < "$owncloud_config"

    result=$(sudo mv "$owncloud_config_tmp" "$owncloud_config")
    checkSuccess "Overwrite the original config.php with the updated content"

    # Use sed to replace the line
    result=$(sudo sed -E -i "s/'overwrite.cli.url' => 'http:\/\/[0-9.:]+'/'overwrite.cli.url' => 'http:\/\/$ip_setup:$usedport\/'/" "$owncloud_config")
    checkSuccess "Updated the internal CLI config IP & Port"

    result=$(sudo chmod --reference="$containers_dir$app_name/files/config/objectstore.config.php" "$owncloud_config")
    checkSuccess "Updating config permissions to associated permissions"

}

dashyUpdateConf() 
{
    # Hardcoded path to Dashy's conf.yml file
    local conf_file="${containers_dir}dashy/conf.yml"

    # Clean up for new generation
    sudo rm -rf "${containers_dir}dashy/conf.yml"

    # Check if Dashy app is installed
    if [ -d "${containers_dir}dashy" ]; then
        echo ""
        echo "#####################################"
        echo "###    Dashy Config Generation    ###"
        echo "#####################################"
        echo ""

        # Copy the default dashy conf.yml configuration file
        local result=$(copyResource "dashy" "conf.yml" "")
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
        uncomment_category_lines() {
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
                        # Call the uncomment_lines function for each app with a category
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
