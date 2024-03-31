#!/bin/bash

fixPermissionsBeforeStart()
{
    local app_name="$1"
    local flag="$2"
    
    if [[ $flag == "update" ]]; then
        echo ""
        echo "##########################################"
        echo "###  Updating File/Folder Permissions  ###"
        echo "##########################################"
        echo ""
    fi

    fixAppFolderPermissions;
    changeRootOwnedFilesAndFolders $script_dir $docker_install_user
    changeRootOwnedFile $docker_dir/$db_file $sudo_user_name

    # App Specific
    if [[ $app_name != "" ]]; then
        changeRootOwnedFilesAndFolders $containers_dir$app_name $docker_install_user
    fi

    # Traefik
    if [ -f "${containers_dir}traefik/etc/certs/acme.json" ]; then
        updateFileOwnership "${containers_dir}traefik/etc/certs/acme.json" $docker_install_user $docker_install_user
        local result=$(sudo chmod 600 "${containers_dir}traefik/etc/certs/acme.json")
        checkSuccess "Set permissions to acme.json file for traefik"
    fi
    if [ -f "${containers_dir}traefik/etc/traefik.yml" ]; then
        updateFileOwnership "${containers_dir}traefik/etc/traefik.yml" $docker_install_user $docker_install_user
        local result=$(sudo chmod 600 "${containers_dir}traefik/etc/traefik.yml")
        checkSuccess "Set permissions to traefik.yml file for traefik"
    fi
}
