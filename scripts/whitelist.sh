#!/bin/bash

app_name="$1"

# Function to update IP whitelist in YAML files
whitelistAndStartApp()
{
    local app_name="$1"

    # Starting variable for app
    setupInstallVariables $app_name;

    # Always keep YML updated
    whitelistUpdateYML $app_name;
    #echo "whitelistUpdateYML $app_name $app_config $app_script;"
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

            # Starting variable for app
            setupInstallVariables $app_name;

            # Always keep YML updated
            whitelistUpdateYML $app_name;
        fi
    done

    isSuccessful "All application whitelists are now up to date."
}

whitelistUpdateYML()
{
    local app_name="$1"

    for yaml_file in "$install_dir/$app_name"/*.yml; do
        if [ -f "$yaml_file" ]; then
            # Check if the YAML file contains ipwhitelist.sourcerange
            if grep -q "ipwhitelist.sourcerange:" "$yaml_file"; then

                # Whitelist not setup yet
                if grep -q "ipwhitelist.sourcerange: IPWHITELIST" "$yaml_file"; then
                    result=$(sudo sed -i "s/ipwhitelist.sourcerange: IPWHITELIST/ipwhitelist.sourcerange: $CFG_IPS_WHITELIST/" "$yaml_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    whitelistUpdateCompose $app_name;
                    whitelistUpdateRestart $app_name;
                    break  # Exit the loop after updating
                fi

                # If the IPs are setup already but need an update
                local current_ip_range=$(grep "ipwhitelist.sourcerange:" "$yaml_file" | cut -d ' ' -f 2)
                if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ] && [ "$current_ip_range" != "IPWHITELIST" ]; then
                    result=$(sudo sed -i "s/ipwhitelist.sourcerange: $current_ip_range/ipwhitelist.sourcerange: $CFG_IPS_WHITELIST/" "$yaml_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    whitelistUpdateCompose $app_name;
                    whitelistUpdateRestart $app_name;
                fi
            fi
        fi
    done
    if [[ "$app_name" == "fail2ban" ]]; then
        if grep -q "ignoreip = ips_whitelist" "$install_dir/$app_name/config/$app_name/jail.local"; then

            # Whitelist not setup yet
            if grep -q "ignoreip = ips_whitelist" "$yaml_file"; then
                result=$(sudo sed -i "s/ips_whitelist/$CFG_IPS_WHITELIST/" "$install_dir/$app_name/config/$app_name/jail.local")
                checkSuccess "Update the IP whitelist for $app_name"
                #echo "whitelistUpdateCompose $app_name;"
                whitelistUpdateCompose $app_name;
                #echo "whitelistUpdateRestart $app_name;"
                whitelistUpdateRestart $app_name;
            fi

            # If the IPs are setup already but needs an update
            local current_ip_range=$(grep "ignoreip = " "$install_dir/$app_name/config/$app_name/jail.local" | cut -d ' ' -f 2)
            if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                result=$(sudo sed -i "s/ignoreip = ips_whitelist/ignoreip = $CFG_IPS_WHITELIST/" "$install_dir/$app_name/config/$app_name/jail.local")
                checkSuccess "Update the IP whitelist for $app_name"
                #echo "whitelistUpdateRestart $app_name"
                whitelistUpdateRestart $app_name;
            fi
        fi
    fi
}

whitelistUpdateCompose()
{
    local app_name="$1"

    if [[ $compose_setup == "default" ]]; then
        editComposeFileDefault $app_name;
    elif [[ $compose_setup == "app" ]]; then
        editComposeFileApp $app_name;
    fi
}

whitelistUpdateRestart()
{
    local app_name="$1"

    if [[ $compose_setup == "default" ]]; then
        dockerDownUpDefault $app_name;
    elif [[ $compose_setup == "app" ]]; then
        dockerDownUpAdditionalYML $app_name;
    fi

}