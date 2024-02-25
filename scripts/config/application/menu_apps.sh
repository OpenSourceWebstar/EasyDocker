#!/bin/bash

viewAppConfigs() 
{
    while true; do
        echo ""
        echo "#################################"
        echo "###        App Categories     ###"
        echo "#################################"
        echo ""
        isOption "1. System Apps"
        isOption "2. Privacy Apps"
        isOption "3. User Apps"
        echo ""
        isQuestion "Please select an option (1/2/3 or 'x' to exit): "
        read -p "" view_app_category_option
        case "$view_app_category_option" in
        1)
            viewAppCategoryConfigs "system"
            ;;
        2)
            viewAppCategoryConfigs "privacy"
            ;;
        3)
            viewAppCategoryConfigs "user"
            ;;
        x)
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for Applications."
                echo ""
                sourceScanFiles "app_configs";
            else
                isNotice "Exiting..."
                return
            fi
            ;;
        *)
            isNotice "Invalid selection. Please choose a valid category or 'x' to exit."
            ;;
        esac
    done
}
