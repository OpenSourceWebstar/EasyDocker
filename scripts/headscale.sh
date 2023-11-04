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
                local preauthkey=$(runCommandForDockerInstallUser "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME")
                checkSuccess "Generating Auth Key in Headscale for $app_name"
                echo "preauthkey $preauthkey"
                setupHeadscaleUser local $preauthkey;
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
    local preauthkey="$2"
    
    # For localhost server installs
    if [[ "$app_name" == "local" ]]; then
        cd ~ && sudo curl -fsSL https://tailscale.com/install.sh | sh
        checkSuccess "Setting up Headscale for $app_name"

        sudo tailscale up --login-server https://$host_setup --authkey $preauthkey
        checkSuccess "Connecting Localhost to Headscale server"
    else
        if [[ "$headscale_setup" == "local" ]]; then
            runCommandForDockerInstallUser "docker exec $app_name curl -fsSL https://tailscale.com/install.sh | sh"
            checkSuccess "Setting up Headscale for $app_name"

            local preauthkey=$(runCommandForDockerInstallUser "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME")
            checkSuccess "Generating Auth Key in Headscale for $app_name"

            runCommandForDockerInstallUser "docker exec $app_name tailscale up --login-server https://$host_setup --authkey $preauthkey"
            checkSuccess "Connecting $app_name to HeadscaleServer "
        elif [[ "$headscale_setup" == "remote" ]]; then
            runCommandForDockerInstallUser "docker exec $app_name curl -fsSL https://tailscale.com/install.sh | sh"
            checkSuccess "Setting up Headscale for $app_name"

            runCommandForDockerInstallUser "docker exec $app_name tailscale up --login-server https://$CFG_HEADSCALE_HOST --authkey $CFG_HEADSCALE_KEY"
            checkSuccess "Connecting $app_name to Headscale Server"
        fi
    fi
}

headscaleCommands()
{
    # Create a key
    if [[ "$headscaleapikeyscreate" == [yY] ]]; then
        echo ""
        isNotice "Headscale Key below :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME"
        checkSuccess "Generating Auth Key in Headscale for user $CFG_INSTALL_NAME"
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of keys
    if [[ "$headscaleapikeyslist" == [yY] ]]; then
        echo ""
        isNotice "Headscale API Key list below :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale apikeys list"
        checkSuccess "Showing all Headscale API Keys."
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of nodes
    if [[ "$headscalenodeslist" == [yY] ]]; then
        echo ""
        isNotice "Headscale Node list below :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale nodes list"
        checkSuccess "Showing all Headscale Nodes."
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of users
    if [[ "$headscaleuserlist" == [yY] ]]; then
        echo ""
        isNotice "Headscale User list below :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale user list"
        checkSuccess "Showing all Headscale Users."
        isNotice "Press Enter to continue..."
        read
    fi 

    # Show version
    if [[ "$headscaleversion" == [yY] ]]; then
        echo ""
        isNotice "Headscale Version below :"
        echo ""
        runCommandForDockerInstallUser "docker exec headscale headscale version"
        checkSuccess "Showing the Headscale Version."
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
