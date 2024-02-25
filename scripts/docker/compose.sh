#!/bin/bash

dockerComposeRestartFile()
{
    local app_name="$1"
    local custom_file="$2"
    local custom_path="$3"

    # Source Filenames
    if [[ $custom_file == "" ]]; then
        local source_compose_file="docker-compose.yml";
    elif [[ $custom_file != "" ]]; then
        local source_compose_file="$custom_file";
    fi

    if [[ $custom_path == "" ]]; then
        local source_path="$install_containers_dir$app_name"
    elif [[ $custom_path != "" ]]; then
        local source_path="$install_containers_dir$app_name/$custom_path/"
    fi

    local source_file="$source_path/$source_compose_file"

    # Target Filenames
    if [[ $compose_setup == "default" ]]; then
        local target_compose_file="docker-compose.yml";
    elif [[ $compose_setup == "app" ]]; then
        local target_compose_file="docker-compose.$app_name.yml";
    fi

    local target_path="$containers_dir$app_name"
    local target_file="$target_path/$target_compose_file"


    if [ "$app_name" == "" ]; then
        isError "The app_name is empty."
        return 1
    fi
    
    if [ ! -f "$source_file" ]; then
        isError "The source file '$source_file' does not exist."
        return 1
    fi
    
    copyFile "loud" "$source_file" "$target_file" $CFG_DOCKER_INSTALL_USER | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
    
    if [ $? -ne 0 ]; then
        isError "Failed to copy the source file to '$target_path'. Check '$docker_log_file' for more details."
        return 1
    fi
}

dockerComposeUpdateAndStartApp()
{
    local app_name="$1"
    local flags="$2"
    local norestart="$3"

    # Starting variable for app
    clearAllPortData;
    setupScanVariables $app_name;

    # Always keep YML updated
    dockerComposeUpdate $app_name $flags $norestart;
}

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

dockerComposeRestartAfterUpdate()
{
    local app_name="$1"
    local flags="$2"

    if [[ $flags == "install" ]] ; then
        dockerComposeRestart $app_name;
        did_not_restart=false
    elif [[ $flags == "" ]] || [[ $flags == "restart" ]]; then
        while true; do
            echo ""
            isNotice "Changes have been made to the $app_name configuration."
            echo ""
            isQuestion "Would you like to restart $app_name? (y/n): "
            echo ""
            read -p "" restart_choice
            if [[ -n "$restart_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$restart_choice" == [yY] ]]; then
            dockerComposeRestart $app_name;
            did_not_restart=false
        fi
        if [[ "$restart_choice" == [nN] ]]; then
            did_not_restart=true
        fi
    fi
}