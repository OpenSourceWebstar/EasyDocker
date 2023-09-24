#!/bin/bash

app_name="$1"

# Function to update IP whitelist in YAML files
whitelistApp()
{
    local app_name="$1"
    # For checking if it's a default compose file or not
    local app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)
    local app_config="$app_dir/$app_name.config"
    local app_script="$app_dir/$app_name.sh"

    # Always keep YML updated
    whitelistUpdateYML $app_name $app_config $app_script
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
            local app_dir=$(find "$containers_dir" -type d -name "$app_name" -print -quit)
            local app_config="$app_dir/$app_name.config"
            local app_script="$app_dir/$app_name.sh"

            # Always keep YML updated
            whitelistUpdateYML $app_name $app_config $app_script
        fi
    done

    isSuccessful "All application whitelists are now up to date."
}

whitelistUpdateYML()
{
    local app_name="$1"
    local app_config="$2"
    local app_script="$3"

    for yaml_file in "$install_dir/$app_name"/*.yml; do
        if [ -f "$yaml_file" ]; then
            # Check if the YAML file contains ipwhitelist.sourcerange
            if grep -q "ipwhitelist.sourcerange:" "$yaml_file"; then
                local current_ip_range=$(grep "ipwhitelist.sourcerange:" "$yaml_file" | cut -d ' ' -f 2)
                if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                    result=$(sudo sed -i "s/ipwhitelist.sourcerange: $current_ip_range/ipwhitelist.sourcerange: $CFG_IPS_WHITELIST/" "$yaml_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    whitelistUpdateCompose $app_name $app_config
                    whitelistUpdateRestart $app_name $app_script
                fi
            fi
        fi
    done
    if [[ "$app_name" == "fail2ban" ]]; then
        if grep -q "ignoreip = ips_whitelist" "$install_dir/$app_name/config/$app_name/jail.local"; then
            local current_ip_range=$(grep "ignoreip = " "$install_dir/$app_name/config/$app_name/jail.local" | cut -d ' ' -f 2)
            if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                result=$(sudo sed -i "s/ignoreip = ips_whitelist/ignoreip = $CFG_IPS_WHITELIST/" "$install_dir/$app_name/config/$app_name/jail.local")
                checkSuccess "Update the IP whitelist for $app_name"
                whitelistUpdateRestart $app_name $app_script
            fi
        fi
    fi
}

whitelistUpdateCompose()
{
    local app_name="$1"
    local app_config="$2"
    
    if grep -q "editComposeFileDefault" $app_config; then
        editComposeFileDefault;
    fi
    
    if grep -q "editComposeFileApp" $app_config; then
        editComposeFileApp;
    fi
}

whitelistUpdateRestart()
{
    local app_name="$1"
    local app_script="$2"
    
    if grep -q "dockerDownUpDefault" $app_script; then
        dockerDownUpDefault $app_name;
    fi
    
    if grep -q "dockerDownUpAdditionalYML" $app_script; then
        dockerDownUpAdditionalYML $app_name;
    fi
}