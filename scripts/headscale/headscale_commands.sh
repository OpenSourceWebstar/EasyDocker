#!/bin/bash

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
        dockerCommandRun "docker exec headscale headscale users create $CFG_INSTALL_NAME"
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
        dockerCommandRun "docker exec headscale headscale users create $CFG_INSTALL_NAME"
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
        dockerCommandRun "docker exec headscale headscale preauthkeys create -e 1h -u $CFG_INSTALL_NAME"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of keys
    if [[ "$headscaleapikeyslist" == [yY] ]]; then
        echo ""
        echo "---- Showing all Headscale API Keys :"
        echo ""
        dockerCommandRun "docker exec headscale headscale apikeys list"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of nodes
    if [[ "$headscalenodeslist" == [yY] ]]; then
        echo ""
        echo "---- Showing all Headscale Nodes :"
        echo ""
        dockerCommandRun "docker exec headscale headscale nodes list"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi

    # Show list of users
    if [[ "$headscaleuserlist" == [yY] ]]; then
        echo ""
        echo "---- Showing all Headscale Users :"
        echo ""
        dockerCommandRun "docker exec headscale headscale user list"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi 

    # Show version
    if [[ "$headscaleversion" == [yY] ]]; then
        echo ""
        checkSuccess "Showing the Headscale Version :"
        echo ""
        dockerCommandRun "docker exec headscale headscale version"
        echo ""
        isNotice "Press Enter to continue..."
        read
    fi
}
