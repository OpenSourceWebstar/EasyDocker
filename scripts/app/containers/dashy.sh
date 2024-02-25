#!/bin/bash

appDashyUpdateConf() 
{
    local conf_file="${containers_dir}dashy/etc/conf.yml"
    local status=$(dockerCheckAppInstalled "dashy" "docker")

    setupAppURL() 
    {
        local app_name="$1"
        setupBasicAppVariable $app_name;

        local dashy_app_url=""
        if [ "$app_public" == "true" ]; then
            dashy_app_url="$app_host_setup"
        else
            dashy_app_url="$app_ip_setup:$app_usedport1"
        fi
        echo "$dashy_app_url"
    }

    # Function to uncomment app lines using sed based on line numbers under the pattern
    uncommentApp() 
    {
        local app_name="$1"
        local pattern="#### app $app_name"
        local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

        if [ -n "$start_line" ]; then
            # Uncomment lines under the app section based on line numbers
            sudo sed -i "$((start_line+1))s/#- title/- title/" "$conf_file"
            sudo sed -i "$((start_line+2))s/#  description/  description/" "$conf_file"
            sudo sed -i "$((start_line+3))s/#  icon/  icon/" "$conf_file"
            sudo sed -i "$((start_line+4))s|#  url: http://APPADDRESSHERE/|  url: http://$(setupAppURL $app_name)/|" "$conf_file"
            sudo sed -i "$((start_line+5))s/#  statusCheck/  statusCheck/" "$conf_file"
            sudo sed -i "$((start_line+6))s/#  target/  target/" "$conf_file"
        fi
    }

    # Function to uncomment category lines using sed based on line numbers under the pattern
    uncommentCategoryForApp() 
    {
        local app_name="$1"
        local pattern="#### category $app_name"
        local start_line=$(grep -n "$pattern" "$conf_file" | cut -d: -f1)

        if [ -n "$start_line" ]; then
            # Uncomment lines under the category section based on line numbers
            sudo sed -i "$((start_line+1))s/^#- name/- name/" "$conf_file"
            sudo sed -i "$((start_line+2))s/^#  icon/  icon/" "$conf_file"
            sudo sed -i "$((start_line+3))s/^#  items/  items/" "$conf_file"
        fi
    }

    # Array to keep track of uncommented categories
    local uncommented_categories=()

    if [ "$status" == "installed" ]; then
        echo ""
        echo "#####################################"
        echo "###    Dashy Config Generation    ###"
        echo "#####################################"
        echo ""

        local original_md5=$(md5sum "$conf_file")

        if [ -f "$conf_file" ]; then
            sudo rm -rf "$conf_file"
            checkSuccess "Removed old Dashy conf.yml for new generation"
        fi

        copyResource "dashy" "conf.yml" "etc"
        checkSuccess "Copy default dashy conf.yml configuration file"

        sudo sed -i "s/INSTALLNAMEHERE/$CFG_INSTALL_NAME/" "$conf_file"

        for app_dir in "${containers_dir}"/*/; do
            if [ -d "$app_dir" ]; then
                local app_name=$(basename "$app_dir")
                local app_config_file="${install_containers_dir}/${app_name}/${app_name}.sh"

                if [ -f "$app_config_file" ]; then
                    local category_info=$(awk -F ': ' '/# Category :/{print $2}' "$app_config_file")

                    if [ -n "$category_info" ] && ! [[ " ${uncommented_categories[@]} " =~ " $category_info " ]]; then
                        uncommentCategoryForApp "$category_info"
                        uncommented_categories+=("$category_info")
                    fi

                    uncommentApp "$app_name"
                fi
            fi
        done

        local updated_md5=$(md5sum "$conf_file")

        if [ "$original_md5" != "$updated_md5" ]; then
            isNotice "Changes made to dashy config file...restarting dashy..."
            dockerCommandRun "docker restart dashy" > /dev/null 2>&1
            isSuccessful "Restarted dashy docker container (if running)"
        else
            isSuccessful "No new changes made to the dashy config file."
        fi
    fi
}
