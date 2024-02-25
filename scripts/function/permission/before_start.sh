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

	if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        # Mainly for "full"
        changeRootOwnedFilesAndFolders $script_dir $CFG_DOCKER_INSTALL_USER
        changeRootOwnedFile $docker_dir/$db_file $sudo_user_name
    fi

    # App Specific
    if [[ $app_name != "" ]]; then
        changeRootOwnedFilesAndFolders $containers_dir$app_name $CFG_DOCKER_INSTALL_USER
    fi

    # Traefik
    if [ -f "${containers_dir}traefik/etc/certs/acme.json" ]; then
        updateFileOwnership "${containers_dir}traefik/etc/certs/acme.json" $CFG_DOCKER_INSTALL_USER $CFG_DOCKER_INSTALL_USER
        local result=$(sudo chmod 600 "${containers_dir}traefik/etc/certs/acme.json")
        checkSuccess "Set permissions to acme.json file for traefik"
    fi
    if [ -f "${containers_dir}traefik/etc/traefik.yml" ]; then
        updateFileOwnership "${containers_dir}traefik/etc/traefik.yml" $CFG_DOCKER_INSTALL_USER $CFG_DOCKER_INSTALL_USER
        local result=$(sudo chmod 600 "${containers_dir}traefik/etc/traefik.yml")
        checkSuccess "Set permissions to traefik.yml file for traefik"
    fi
}
