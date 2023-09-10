#!/bin/bash

app_name="$1"

uninstallApp()
{
    echo ""
    echo "##########################################"
    echo "###      Uninstalling $app_name"
    echo "##########################################"

	((menu_number++))
    echo ""
    echo "---- $menu_number. Removing app where docker-compose is installed"
    echo ""

    dockerDownRemove;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Deleting all app data from docker folder"
    echo ""

    dockerDeleteData;

	((menu_number++))
    echo ""
    echo "---- $menu_number. Marking app as uninstalled in the database"
    echo ""

    databaseUninstallApp;

	((menu_number++))
    echo ""
    isSuccessful "$app_name has been removed from your system!"
    echo ""
    
	menu_number=0
    cd
}

dockerDownRemove()
{
    cd $install_path$app_name
    if [[ "$OS" == [123] ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
            result=$(runCommandForDockerInstallUser "docker-compose down -v --rmi all --remove-orphans")
            isSuccessful "Shutting down & Removing all $app_name container data"
        elif [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            result=$(sudo -u $easydockeruser docker-compose down -v --rmi all --remove-orphans)
            isSuccessful "Shutting down & Removing all $app_name container data"
        fi
    fi
}

dockerDeleteData()
{
    result=$(sudo rm -rf $install_path$app_name)
    checkSuccess "Deleting $app_name install folder"
}