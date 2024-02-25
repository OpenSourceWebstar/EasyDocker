#!/bin/bash

viewConfigs() 
{
    while true; do
        echo ""
        echo "#################################"
        echo "###    Manage Config Files    ###"
        echo "#################################"
        echo ""
        isOption "1. EasyDocker configs"
        isOption "2. App configs"
        echo ""
        isQuestion "Please select an option (1 or 2, or 'x' to exit): "
        read -p "" view_config_option
        case "$view_config_option" in
        1)
            viewEasyDockerConfigs
            ;;
        2)
            viewAppConfigs
            ;;
        x)
            endStart;
            ;;
        *)
            isNotice "Invalid option. Please choose a valid option or 'x' to exit."
            ;;
        esac
    done
}
