#!/bin/bash

fixConfigPermissions()
{
    local silent_flag="$1"
    local app_name="$2"
    local config_file="$containers_dir$app_name/$app_name.config"

    local result=$(sudo chmod g+rw $config_file)
    if [ "$silent_flag" == "loud" ]; then
        isNotice "Updating config read permissions for EasyDocker"
    fi

    fixFolderPermissions $silent_flag $app_name;
}
