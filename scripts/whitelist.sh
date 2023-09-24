#!/bin/bash

app_name="$1"

# Function to update IP whitelist in YAML files
whitelistApp()
{
    local app_name="$1"
    # For checking if it's a default compose file or not
    app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)
    app_config="$app_dir/$app_name.config"

    if grep -q "WHITELIST=true" "$app_config"; then
        for yaml_file in "$app_name_dir"/*.yml; do
            if [ -f "$yaml_file" ]; then
                # Check if the YAML file contains ipwhitelist.sourcerange
                if grep -q "ipwhitelist.sourcerange:" "$yaml_file"; then
                    local current_ip_range=$(grep "ipwhitelist.sourcerange:" "$yaml_file" | cut -d ' ' -f 2)
                    if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                        update_whitelist=true
                    fi
                fi
                if [[ "$app_name" == "fail2ban" ]]; then
                    if grep -q "ignoreip = ips_whitelist" "$install_dir/$app_name/config/$app_name/jail.local"; then
                        local current_ip_range=$(grep "ignoreip = " "$install_dir/$app_name/config/$app_name/jail.local" | cut -d ' ' -f 2)
                        if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                            update_whitelist=true
                        fi
                    fi
                fi
            fi
        done
        if [ "$update_whitelist" == "true" ]; then
            updateWhitelistYML $app_name $current_ip_range $yaml_file
            updateWhitelistRestart $app_name
            isSuccessful "Updated whitelist for $app_name"
        fi
    fi
}

# Function to update IP whitelist in YAML files
whitelistScan()
{
    echo ""
    echo "#####################################"
    echo "###       Whitelist Updater       ###"
    echo "#####################################"
    echo ""
    for app_name_dir in "$install_dir"/*/; do
        if [ -d "$app_name_dir" ]; then
            local app_name=$(basename "$app_name_dir")

            # For checking if it's a default compose file or not
            app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)
            app_config="$app_dir/$app_name.config"

            if grep -q "WHITELIST=true" "$app_config"; then
                for yaml_file in "$app_name_dir"/*.yml; do
                    if [ -f "$yaml_file" ]; then
                        # Check if the YAML file contains ipwhitelist.sourcerange
                        if grep -q "ipwhitelist.sourcerange:" "$yaml_file"; then
                            local current_ip_range=$(grep "ipwhitelist.sourcerange:" "$yaml_file" | cut -d ' ' -f 2)
                            if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                                update_whitelist=true
                            fi
                        fi
                        if [[ "$app_name" == "fail2ban" ]]; then
                            if grep -q "ignoreip = ips_whitelist" "$install_dir/$app_name/config/$app_name/jail.local"; then
                                local current_ip_range=$(grep "ignoreip = " "$install_dir/$app_name/config/$app_name/jail.local" | cut -d ' ' -f 2)
                                if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                                    update_whitelist=true
                                fi
                            fi
                        fi
                    fi
                done
                if [ "$update_whitelist" == "true" ]; then
                    whitelistUpdateYML $app_name $current_ip_range $yaml_file
                    whitelistUpdateRestart $app_name
                    isSuccessful "Updated whitelist for $app_name"
                fi
            fi
        fi
    done

    isSuccessful "All application whitelists are updated"
}

whitelistUpdateYML()
{
    local app_name="$1"
    local current_ip_range="$2"
    local yaml_file="$3"
    if [[ "$app_name" == "fail2ban" ]]; then
        result=$(sudo sed -i "s/ignoreip = ips_whitelist/ignoreip = $CFG_IPS_WHITELIST/" "$install_dir/$app_name/config/$app_name/jail.local")
        checkSuccess "Update the IP whitelist for $app_name"
    else
        result=$(sudo sed -i "s/ipwhitelist.sourcerange: $current_ip_range/ipwhitelist.sourcerange: $CFG_IPS_WHITELIST/" "$yaml_file")
        checkSuccess "Update the IP whitelist for $app_name"
    fi
}


whitelistUpdateRestart()
{
    local app_name="$1"
    
    # For checking if it's a default compose file or not
    app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)
    app_script="$app_dir/$app_name.sh"
    
    if grep -q "dockerDownUpDefault" $app_script; then
        dockerDownUpDefault;
    fi
    
    if grep -q "dockerDownUpAdditionalYML" $app_script; then
        dockerDownUpAdditionalYML;
    fi
}