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

        CloseAppPorts $stored_app_name;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Marking app as uninstalled in the database"
        echo ""

        databaseUninstallApp $stored_app_name;

        ((menu_number++))
        echo ""
        isSuccessful "$app_name has been removed from your system!"
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
        if [[ "$OS" == [123] ]]; then
            if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
                result=$(runCommandForDockerInstallUser "cd $install_dir$app_name && docker-compose down -v --rmi all --remove-orphans")
                isNotice "Shutting down & Removing all $app_name container data"
            elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
                result=$(cd $install_dir$app_name && sudo -u $easydockeruser docker-compose down -v --rmi all --remove-orphans)
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
        result=$(sudo rm -rf $install_dir$app_name)
        checkSuccess "Deleting $app_name install folder"
    fi

}