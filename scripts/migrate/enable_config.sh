#!/bin/bash

migrateEnableConfig()
{
    while true; do
        isQuestion "Do you want to enable migration in the config file? (y/n): "
        read -rp "" enableconfigmigrate
        if [[ "$enableconfigmigrate" =~ ^[yYnN]$ ]]; then
            break
        fi
        isNotice "Please provide a valid input (y/n)."
    done
    if [[ $enableconfigmigrate == [yY] ]]; then
        local result=$(sudo sed -i "s/CFG_REQUIREMENT_MIGRATE="false"/CFG_REQUIREMENT_MIGRATE="true"/" "$configs_dir/$config_file_requirements")
        checkSuccess "Enabling CFG_REQUIREMENT_MIGRATE in $config_file_requirements"
    fi
    if [[ $enableconfigmigrate == [nN] ]]; then
        isNotice "Unable to enable migration."
        return 1
    fi

}
