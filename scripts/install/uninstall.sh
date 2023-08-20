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
    # This can error for many reasons so no checkSuccess
    if [[ "$OS" == "1" ]]; then
        result=$(cd $install_path$app_name && docker-compose down -v --rmi all --remove-orphans)
        isSuccessful "Shutting down & Removing all $app_name container data"
    else
        result=$(cd $install_path$app_name && sudo docker-compose down -v --rmi all --remove-orphans)
        isSuccessful "Shutting down & Removing all $app_name container data"
    fi
}

dockerDeleteData()
{
    result=$(rm -rf $install_path$app_name)
    checkSuccess "Deleting $app_name install folder"
}