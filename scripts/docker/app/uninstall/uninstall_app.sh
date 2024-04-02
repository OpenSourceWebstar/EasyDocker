#!/bin/bash

dockerUninstallApp()
{
    local app_name="$1"
    local stored_app_name=$app_name

    if [[ "$stored_app_name" == "" ]]; then
        isError "No app_name provided, unable to continue..."
        return
    else
        echo ""
        echo "##########################################"
        echo "###      Uninstalling $stored_app_name"
        echo "##########################################"
        portClearAllData;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Removing app where docker-compose is installed"
        echo ""

        dockerComposeDownRemove $stored_app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Deleting all app data from docker folder"
        echo ""

        dockerDeleteData $stored_app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Closing ports if required"
        echo ""

        setupInstallVariables $stored_app_name;
        portsRemoveApp $stored_app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Removing unused Docker networks."
        echo ""

        dockerPruneAppNetworks $stored_app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Marking app as uninstalled in the database"
        echo ""

        databaseUninstallApp $stored_app_name;

        ((menu_number++))
        echo ""
        isSuccessful "$stored_app_name has been removed from your system!"
        echo ""
        
        menu_number=0
        cd
    fi
}
