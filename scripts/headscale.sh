#!/bin/bash

setupHeadscaleVariables()
{
    local app_name="headscale"

    if [[ "$app_name" == "" ]]; then
        isError "Something went wrong...No app name provided..."
        resetToMenu;
    fi

    # Build variable names based on app_name
    headscale_host_name_var="CFG_${app_name^^}_HOST_NAME"
    headscale_domain_number_var="CFG_${app_name^^}_DOMAIN_NUMBER"

    # Access the variables using variable indirection
    headscale_host_name="${!headscale_host_name_var}"
    headscale_domain_number="${!headscale_domain_number_var}"

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

    setupHeadscaleVariables $app_name;

    # Convert CFG_INSTALL_NAME to lowercase
    local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')

    status=$(checkAppInstalled "headscale" "docker")
    if [ "$status" == "installed" ]; then
        # We don't setup headscale for headscale :)
        if [[ "$app_name" == "headscale" ]]; then
            runCommandForDockerInstallUser "docker exec headscale headscale users create $CFG_INSTALL_NAME"
            checkSuccess "Creating Headscale user $CFG_INSTALL_NAME"
            # We will setup Localhost
			while true; do
				echo ""
				isQuestion "Would you like to connect your localhost server the Headscale server? (y/n) "
				read -p "" local_headscale
				if [[ -n "$local_headscale" ]]; then
					break
				fi
				isNotice "Please provide a valid input."
			done
			if [[ "$local_headscale" == [yY] ]]; then
                setupHeadscaleUser localhost;
			fi
        else
            if [[ "$headscale_setup" != "disabled" ]]; then
                setupHeadscaleUser $app_name;
            fi
        fi
    else
        isSuccessful "Headscale is not installed, continuing with installation..."
    fi

}

setupHeadscaleUser()
{
    local app_name="$1"
    
    if [[ "$headscale_setup" == "local" ]]; then
        setupHeadscaleLocal $app_name;
    elif [[ "$headscale_setup" == "remote" ]]; then
        setupHeadscaleRemote $app_name;
    fi
}

setupHeadscaleLocal()
{
    local app_name="$1"

    runCommandForDockerInstallUser "docker exec $app_name curl -fsSL https://tailscale.com/install.sh | sh"
    checkSuccess "Setting up Headscale for $app_name"

    local CFG_INSTALL_NAME=$(echo "$CFG_INSTALL_NAME" | tr '[:upper:]' '[:lower:]')
    local preauthkey=$(runCommandForDockerInstallUser "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME")
    checkSuccess "Generating Auth Key in Headscale for $app_name"

    runCommandForDockerInstallUser "docker exec $app_name tailscale up --login-server https://$host_setup --authkey $preauthkey"
    checkSuccess "Connecting $app_name to HeadscaleServer"
}

setupHeadscaleRemote()
{
    local app_name="$1"

    runCommandForDockerInstallUser "docker exec $app_name curl -fsSL https://tailscale.com/install.sh | sh"
    checkSuccess "Setting up Headscale for $app_name"

    runCommandForDockerInstallUser "docker exec $app_name tailscale up --login-server https://$CFG_HEADSCALE_HOST --authkey $CFG_HEADSCALE_KEY"
    checkSuccess "Connecting $app_name to Headscale Server"
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
        checkSuccess ""
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
    nano "$config_file"
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
