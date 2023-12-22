#!/bin/bash

setupHeadscaleVariables()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    headscale_host_name_var="CFG_${app_name^^}_HOST_NAME"
    headscale_domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"
    headscale_setup_var="CFG_${app_name^^}_HEADSCALE"

    # Access the variables using variable indirection
    headscale_host_name="${!headscale_host_name_var}"
    headscale_domain_number="${!headscale_domain_number_var}"
    headscale_setup="${!headscale_setup_var}"

    # Check if no network needed
    if [ "$headscale_host_name" != "" ]; then
        while read -r line; do
            local headscale_hostname=$(echo "$line" | awk '{print $1}')
            local headscale_ip=$(echo "$line" | awk '{print $2}')
            if [ "$headscale_hostname" = "$headscale_host_name" ]; then
                headscale_domain_prefix=$headscale_hostname
                headscale_domain_var_name="CFG_DOMAIN_${headscale_domain_number}"
                headscale_domain_full=$(sudo grep  "^$headscale_domain_var_name=" $configs_dir/config_general | cut -d '=' -f 2-)
                headscale_host_setup=${headscale_domain_prefix}.${headscale_domain_full}
                headscale_ip_setup=$headscale_ip
            fi
        done < "$configs_dir$ip_file"
    fi 
}

setupHeadscale() 
{
    local app_name="$1"
    local local_type="$2"

    if [ "$app_name" != "localhost" ]; then
        setupHeadscaleVariables "$app_name"
    fi

    local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
    local status=$(checkAppInstalled "headscale" "docker")

    if [ "$status" == "installed" ]; then
        # We don't set up headscale for headscale
        if [[ "$app_name" == "headscale" ]]; then
            runCommandForDockerInstallUser "docker exec headscale headscale users create $CFG_INSTALL_NAME"
            checkSuccess "Creating Headscale user $CFG_INSTALL_NAME"

            while true; do
                echo ""
                isQuestion "Would you like to connect your localhost client to the Headscale server? (y/n) "
                read -p "" local_headscale
                if [[ -n "$local_headscale" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done

            if [[ "$local_headscale" == [yY] ]]; then
                setupHeadscaleUser localhost local
            fi
        elif [[ "$app_name" == "localhost" ]]; then
            while true; do
                echo ""
                isQuestion "Would you like to set up your localhost Headscale client to Localhost or Remote? (l/r) "
                read -p "" localhost_type_headscale
                if [[ -n "$localhost_type_headscale" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done

            if [[ "$localhost_type_headscale" == [lL] ]]; then
                setupHeadscaleUser localhost local
            elif [[ "$localhost_type_headscale" == [rR] ]]; then
                setupHeadscaleUser localhost remote
            fi
        else
            if [[ "$headscale_setup" != "disabled" ]]; then
                setupHeadscaleUser "$app_name"
            elif [[ "$headscale_setup" == "disabled" || "$headscale_setup" == "" ]]; then
                isNotice "Headscale is not enabled for $app_name, unable to install."
            fi
        fi
    else
        isSuccessful "Headscale is not installed."
    fi
}

setupHeadscaleUser()
{
    local app_name="$1"
    local local_type="$2"
    
    isNotice "Setting up Headscale for $app_name"
    
    if [[ "$app_name" == "localhost" ]]; then
        setupHeadscaleLocalhost $local_type;
    fi

    if [[ "$headscale_setup" == *"local"* ]]; then
        setupHeadscaleLocal $app_name;
    fi

    if [[ "$headscale_setup" == *"remote"* ]]; then
        if setupHeadscaleCheckRemote; then
            setupHeadscaleRemote $app_name;
        fi
    fi

    if [[ "$headscale_setup" == "" ]]; then
        echo ""
        isNotice "Headscale is no setup for $app_name."
        isNotice "Please setup the config"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi
}

setupHeadscaleCheckRemote()
{
    if [[ "$CFG_HEADSCALE_HOST" == "" ]]; then
        isError "Please setup a Headscale host in the EasyDocker General config for CFG_HEADSCALE_HOST"
        return
    fi
    if [[ "$CFG_HEADSCALE_KEY" == "" ]]; then
        isError "Please setup a Headscale Key in the EasyDocker General config for CFG_HEADSCALE_KEY"
        return
    fi
    isSuccessful "Remote Headscale config data has been provided...continuing..."
}   

setupHeadscaleLocalhost()
{
    local local_type="$1"
    if [[ "$local_type" == "local" ]]; then
        local status=$(checkAppInstalled "headscale" "docker")
        if [ "$status" == "installed" ]; then
            setupHeadscaleGetHostname;

            result=$(cd ~ && curl -fsSL https://tailscale.com/install.sh | sh)
            checkSuccess "Setting up Headscale for localhost"

            setupHeadscaleGenerateAuthKey;

            result=$(sudo tailscale up --login-server $headscale_live_hostname --authkey $headscale_preauthkey --force-reauth)
            checkSuccess "Connecting $app_name to Headscale Server"

            result=$(rm -rf $headscale_preauthkey_file)
            checkSuccess "Clearing the temp key file."

            # Showing Nodelist after install
            headscaleclientlocal=n
            headscalenodeslist=y
            headscaleCommands;
            headscalenodeslist=n
        else
            isSuccessful "Headscale is not installed, Unable to install."
        fi
    elif [[ "$local_type" == "remote" ]]; then
        if setupHeadscaleCheckRemote; then
            result=$(cd ~ && curl -fsSL https://tailscale.com/install.sh | sh)
            checkSuccess "Setting up Headscale"

            result=$(sudo tailscale up --login-server https://$CFG_HEADSCALE_HOST --authkey $CFG_HEADSCALE_KEY --force-reauth)
            checkSuccess "Connecting $app_name to $CFG_HEADSCALE_HOST Headscale Server"
        fi
    fi
}

setupHeadscaleLocal()
{
    local app_name="$1"

    setupHeadscaleGetHostname;

    tailscaleInstallToContainer $app_name;

    setupHeadscaleGenerateAuthKey;

    runCommandForDockerInstallUser "docker exec $app_name tailscale up --login-server $headscale_host_setup --authkey $headscale_preauthkey --force-reauth"
    checkSuccess "Connecting $app_name to Headscale Server"

    result=$(rm -rf $headscale_preauthkey_file)
    checkSuccess "Clearing the temp key file."

    # Showing Nodelist after install
    headscaleclientlocal=n
    headscalenodeslist=y
    headscaleCommands;
    headscalenodeslist=n
}

setupHeadscaleRemote()
{
    local app_name="$1"

    tailscaleInstallToContainer $app_name;

    runCommandForDockerInstallUser "docker exec $app_name tailscale up --login-server https://$CFG_HEADSCALE_HOST --authkey $CFG_HEADSCALE_KEY --force-reauth"
    checkSuccess "Connecting $app_name to Headscale Server"
}

setupHeadscaleGenerateAuthKey()
{
    headscale_preauthkey=""
    local temp_key_file="/docker/key.txt"

    local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
    runCommandForDockerInstallUser "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME" > "$temp_key_file" 2>&1
    checkSuccess "Generating Auth Key in Headscale for $app_name"

    headscale_preauthkey=$(tr -d '\n' < "$temp_key_file")
    headscale_preauthkey_file="$temp_key_file"
}

setupHeadscaleGetHostname()
{
    local config_file="${containers_dir}headscale/config/config.yaml"
    if [ -f "$config_file" ]; then
        # Read the line with "server_url" and extract the hostname
        headscale_live_hostname=$(grep "server_url:" "$config_file" | awk -F'server_url: ' '{print $2}')

        # Check if the hostname was found
        if [ -n "$headscale_live_hostname" ]; then
            isSuccessful "Hostname for Headscale found: $headscale_live_hostname"
        else
            isError "Hostname not found in $config_file."
        fi
    else
        isError "Headscale config File $config_file not found."
    fi
}

headscaleCommands()
{
    # Setup Headscale for Localhost
    if [[ "$headscaleclientlocal" == [yY] ]]; then
        setupHeadscale localhost;
    fi
    
    # Setup Headscale for app
    if [[ "$headscaleclientapp" == [yY] ]]; then
        local app_names=()
        local app_dir

        echo ""
        echo "#########################################"
        echo "###    Install Headscale Apps List    ###"
        echo "#########################################"
        echo ""

        # Find all subdirectories under the directory where your apps are installed
        for app_dir in "$containers_dir"/*/; do
            if [[ -d "$app_dir" ]]; then
            # Extract the app name (folder name)
            local app_name=$(basename "$app_dir")
            local app_names+=("$app_name")
            fi
        done

        # Check if any apps were found
        if [ ${#app_names[@]} -eq 0 ]; then
            isNotice "No apps found in the installation directory."
            return
        fi

        # List numbered options for app names
        isNotice "Select an app to set up Headscale for:"
        echo ""
        for i in "${!app_names[@]}"; do
            isOption "$((i + 1)). ${app_names[i]}"
        done

        # Read user input for app selection
        echo ""
        isQuestion "Enter the number of the app (or 'x' to exit): "
        read -p "" selected_option

        case "$selected_option" in
            [1-9]*)
            # Check if the selected option is a valid number
            if ((selected_option >= 1 && selected_option <= ${#app_names[@]})); then
                local selected_app="${app_names[selected_option - 1]}"
                
                # Call the setupHeadscale function with the selected app name
                setupHeadscale "$selected_app"
            else
                isNotice "Invalid app number. Please choose a valid option."
            fi
            ;;
            x)
            isNotice "Exiting..."
            return
            ;;
            *)
            isNotice "Invalid option. Please choose a valid option or 'x' to exit."
            ;;
        esac
    fi

    # Create a user
    if [[ "$headscaleusercreate" == [yY] ]]; then
        echo ""
        echo "---- Creating user $CFG_INSTALL_NAME for Headscale :"
        echo ""
        local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
        runCommandForDockerInstallUser "docker exec headscale headscale users create $CFG_INSTALL_NAME"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Create a user
    if [[ "$headscaleusercreate" == [yY] ]]; then
        echo ""
        echo "---- Creating user $CFG_INSTALL_NAME for Headscale :"
        echo ""
        local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
        runCommandForDockerInstallUser "docker exec headscale headscale users create $CFG_INSTALL_NAME"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Create a key
    if [[ "$headscaleapikeyscreate" == [yY] ]]; then
        echo ""
        echo "---- Generating Auth Key in Headscale for user $CFG_INSTALL_NAME :"
        echo ""
        local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
        runCommandForDockerInstallUser "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of keys
    if [[ "$headscaleapikeyslist" == [yY] ]]; then
        echo ""
        echo "---- Showing all Headscale API Keys :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale apikeys list"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of nodes
    if [[ "$headscalenodeslist" == [yY] ]]; then
        echo ""
        echo "---- Showing all Headscale Nodes :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale nodes list"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of users
    if [[ "$headscaleuserlist" == [yY] ]]; then
        echo ""
        echo "---- Showing all Headscale Users :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale user list"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi 

    # Show version
    if [[ "$headscaleversion" == [yY] ]]; then
        echo ""
        checkSuccess "Showing the Headscale Version :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale version"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi
}

headscaleEditConfig() 
{
    local config_file="${containers_dir}headscale/config/config.yaml"
    local previous_md5=$(md5sum "$config_file" | awk '{print $1}')
    $CFG_TEXT_EDITOR "$config_file"
    local current_md5=$(md5sum "$config_file" | awk '{print $1}')

    if [ "$previous_md5" != "$current_md5" ]; then
        while true; do
            echo ""
            isNotice "Changes have been made to the Headscale configuration."
            echo ""
            isQuestion "Would you like to restart Headscale? (y/n): "
            echo ""
            read -p "" restart_headscale
            if [[ -n "$restart_headscale" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$restart_choice" == [yY] ]]; then
            dockerDownUp "headscale";
        fi
    fi
}

tailscaleInstallToContainer()
{
    local app_name="$1"
    local type="$2"

    local result=$(mkdirFolders "loud" $CFG_DOCKER_INSTALL_USER $containers_dir$app_name/tailscale)
    checkSuccess "Creating Tailscale folder"

    copyFile "loud" "${install_scripts_dir}tailscale.sh" "$containers_dir$app_name/tailscale/tailscale.sh" $CFG_DOCKER_INSTALL_USER | sudo -u $sudo_user_name tee -a "$logs_dir/$docker_log_file" 2>&1

    if [[ "$type" != "install" ]]; then
        dockerDownUp $app_name;
    fi
    #runCommandForDockerInstallUser "docker cp ${install_scripts_dir}tailscale.sh $app_name:/usr/local/bin/tailscale.sh"
    #checkSuccess "Installing Tailscale installer script into the $app_name container"

    runCommandForDockerInstallUser "docker exec -it $app_name /usr/local/bin/tailscale.sh"
    checkSuccess "Executing Tailscale installer script in the $app_name container"
}