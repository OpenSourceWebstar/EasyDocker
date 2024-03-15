#!/bin/bash

dockerScan()
{
    echo ""
    echo "#####################################"
    echo "###     Whitelist/Port Updater    ###"
    echo "#####################################"
    echo ""
    for app_name_dir in "$containers_dir"/*/; do
        if [ -d "$app_name_dir" ]; then
            local app_name=$(basename "$app_name_dir")

            # Starting variable for app
            portClearAllData;
            setupBasicScanVariables $app_name;
    
            # Always keep YML updated
            dockerComposeUpdate $app_name scan;

            # Update ports for the app
            portsCheckApp $app_name scan;

            # If there is any UFWD Ports to open
            portOpenAllUfwdPorts $app_name;
        fi
    done

    traefikUpdateWhitelist;
    portHandleAllConflicts;

    isSuccessful "All application whitelists are up to date."
}


