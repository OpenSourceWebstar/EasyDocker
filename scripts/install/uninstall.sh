#!/bin/bash

uninstallApp()
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

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Removing app where docker-compose is installed"
        echo ""

        dockerDownRemove $stored_app_name;

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
        removeAppPorts $stored_app_name;

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

dockerDownRemove()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "No app_name provided, unable to continue..."
        return
    else
        if [[ "$OS" == [1234567] ]]; then
            if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
                local result=$(runCommandForDockerInstallUser "cd $containers_dir$app_name && docker-compose down -v --rmi all --remove-orphans")
                isNotice "Shutting down & Removing all $app_name container data"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
                local result=$(cd $containers_dir$app_name && sudo -u $easydockeruser docker-compose down -v --rmi all --remove-orphans)
                isNotice "Shutting down & Removing all $app_name container data"
            fi
        fi
    fi
}

dockerDeleteData()
{
    local app_name="$1"

    if [[ "$app_name" == "" ]]; then
        isError "No app_name provided, unable to continue..."
        return
    else
        local result=$(sudo rm -rf $containers_dir$app_name)
        checkSuccess "Deleting $app_name install folder"
    fi

}