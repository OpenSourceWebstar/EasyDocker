#!/bin/bash

dockerComposeUpdate()
{
    local app_name="$1"
    local flags="$2"
    local norestart="$3"

    local whitelistupdates=false
    local timezoneupdates=false

    if [[ $compose_setup == "default" ]]; then
        local compose_file="docker-compose.yml"
    elif [[ $compose_setup == "app" ]]; then
        local compose_file="docker-compose.$app_name.yml"
    fi

    # Whitelist update for yml files
    for yaml_file in "$containers_dir/$app_name"/$compose_file; do
        if [ -f "$yaml_file" ]; then
            # This is for updating Timzeones
            if sudo grep -q " TZ=" "$yaml_file"; then
                if sudo grep -q " TZ=TIMEZONEHERE" "$yaml_file"; then
                    local result=$(sudo sed -i "s| TZ=TIMEZONEHERE| TZ=$CFG_TIMEZONE|" "$yaml_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    local timezoneupdates=true
                    break  # Exit the loop after updating
                fi
                # If the timzones are setup already but need an update
                local current_timezone=""
                local current_timezone=$(grep " TZ=" "$yaml_file" | cut -d '=' -f 2 | xargs)
                if [ "$current_timezone" != "$CFG_TIMEZONE" ] && [ "$current_timezone" != "TIMEZONEHERE" ]; then
                    local result=$(sudo sed -i "s| TZ=$current_timezone| TZ=$CFG_TIMEZONE|" "$yaml_file")
                    checkSuccess "Update the Timezone for $app_name"
                    local timezoneupdates=true
                fi
            fi
        fi
    done

    # Fail2ban specifics
    if [[ "$app_name" == "fail2ban" ]]; then
        local jail_local_file="$containers_dir/$app_name/config/$app_name/jail.local"
        
        if [ -f "$jail_local_file" ]; then
            if sudo grep -q "ignoreip = ips_whitelist" "$jail_local_file"; then

                # Whitelist not set up yet
                if sudo grep -q "ignoreip = ips_whitelist" "$yaml_file"; then
                    local result=$(sudo sed -i "s/ips_whitelist/$CFG_IPS_WHITELIST/" "$jail_local_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    local whitelistupdates=true
                fi

                # If the IPs are set up already but need an update
                local current_ip_range=$(grep "ignoreip = " "$jail_local_file" | cut -d ' ' -f 2)
                if [ "$current_ip_range" != "$CFG_IPS_WHITELIST" ]; then
                    local result=$(sudo sed -i "s/ignoreip = ips_whitelist/ignoreip = $CFG_IPS_WHITELIST/" "$jail_local_file")
                    checkSuccess "Update the IP whitelist for $app_name"
                    local whitelistupdates=true
                fi
            fi
        fi
    fi

    if [ "$flags" == "install" ]; then
        dockerConfigSetupFileWithData $app_name;
        if [[ $norestart != "norestart" ]]; then
            dockerComposeRestartAfterUpdate $app_name $flags;
        fi
        if [ "$timezoneupdates" == "true" ]; then
            if [ "$did_not_restart" == "true" ]; then
                isSuccessful "The timezone for $app_name is now up to date."
                isNotice "Please restart $app_name to apply any updates."
            else
                isSuccessful "The timezone for $app_name is now up to date and restarted."
            fi
        fi
        local timezoneupdates=false
        did_not_restart=false
    fi

    if [ "$flags" == "scan" ]; then
        if [ "$timezoneupdates" == "true" ]; then
            if [ "$did_not_restart" == "true" ]; then
                isSuccessful "The timezone for $app_name is now up to date."
                isNotice "Please restart $app_name to apply any updates."
            else
                isSuccessful "The timezone for $app_name is now up to date and restarted."
            fi
        fi
        local timezoneupdates=false
        did_not_restart=false
    fi

    if [ "$flags" == "restart" ]; then
        dockerConfigSetupFileWithData $app_name;
        if [[ $norestart != "norestart" ]]; then
            dockerComposeRestartAfterUpdate $app_name $flags;
        fi
    fi
}
