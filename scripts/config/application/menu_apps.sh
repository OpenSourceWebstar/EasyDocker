#!/bin/bash

viewAppConfigs() 
{
    while true; do
        echo ""
        echo "#################################"
        echo "###        App Categories     ###"
        echo "#################################"
        echo ""

        for i in "${!app_categories[@]}"; do
            local capitalized_category=$(echo "${app_categories[$i]}" | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
            isOption "$((i + 1)). ${capitalized_category} App"
        done
        echo ""
        isQuestion "Please select an option (1-${#app_categories[@]} or 'x' to exit): "
        read -p "" view_app_category_option

        # Validate input
        if [[ "$view_app_category_option" =~ ^[1-9][0-9]*$ ]] && [ "$view_app_category_option" -le "${#app_categories[@]}" ]; then
            selected_category="${app_categories[$((view_app_category_option - 1))]}"
            viewAppCategoryConfigs "$selected_category"
        elif [[ "$view_app_category_option" == "x" ]]; then
            if [[ $config_edited == "true" ]]; then
                echo ""
                isNotice "Reloading configuration file(s) for Applications."
                echo ""
                sourceScanFiles "app_configs"
            else
                isNotice "Exiting..."
                return
            fi
        else
            isNotice "Invalid selection. Please choose a valid category or 'x' to exit."
        fi
    done
}
