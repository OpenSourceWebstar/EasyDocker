#!/bin/bash

appGenerate()
{
    local app_name="$1"
    
    echo ""
    echo "####################################################"
    echo "###      EasyDocker Application Generator        ###"
    echo "####################################################"
    echo ""
    isNotice "USAGE : This is for generating new container installation scripts for EasyDocker"
    echo ""

    while true; do
        if [[ "$app_name" == "" ]]; then
            read -p "Please enter the name of the application you would like to create a script for: " app_name
        fi

        if [[ -d "$install_containers_dir$app_name" ]]
        then
            isError "Error: A folder with that name already exists. Please choose another name."
            echo ""
        else
            isSuccessful "Valid application name given."
            local cap_first_app_name=$(echo "$app_name" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
            local full_caps_app_name=$(echo "$app_name" | awk '{print toupper($0)}')
            echo ""
            break
        fi
    done

    while true; do
        isQuestion "Please enter the hostname (e.g a hostname 'test' would be setup the domain : test.yourdomain.com): "
        read -p "" host_name
        if [[ $? -eq 0 ]]; then
            break
        fi
        echo "Please provide a valid hostname"
    done

    while true; do
        isQuestion "Please enter a short description (e.g a Finance Mananger): "
        read -p "" app_description
        if [[ $? -eq 0 ]]; then
            break
        fi
        echo "Please provide a valid description"
    done

    while true; do
        isQuestion "Please select the application category:"
        echo ""
        # Capitalize the first letter of each category for better viewing
        local capitalized_category=$(echo "${app_categories[$i]}" | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
        for i in "${!app_categories[@]}"; do
            echo "$((i + 1)). ${capitalized_category[$i]^} App"
        done
        echo ""
        isQuestion "Enter your choice (1-${#app_categories[@]}): "
        read -rp "" app_selection
        echo ""

        # Validate input
        if [[ "$app_selection" =~ ^[1-9][0-9]*$ ]] && [ "$app_selection" -le "${#app_categories[@]}" ]; then
            local selected_category="${app_categories[$((app_selection - 1))]}"
            echo "Application will be set to a ${selected_category^} App"
            local app_category=$selected_category
            break
        else
            isNotice "Invalid choice. Please enter a number between '1' and '${#app_categories[@]}'."
        fi
    done

    if [[ ! -d "$install_containers_dir$app_name" ]]; then
        local result=$(createFolders "loud" $docker_install_user $install_containers_dir$app_name)
        checkSuccess "Creating new folder named $app_name"

        local result=$(cp -r $install_containers_dir/template/* $install_containers_dir$app_name)
        checkSuccess "Copying template files to the $app_name folder"

        local result=$(mv template.sh "$app_name.sh")
        checkSuccess "Renaming script file for $app_name"

        local result=$(mv template.config "$app_name.config")
        checkSuccess "Renaming config file for $app_name"

        echo "Renaming of files completed successfully."

        local app_script_file="$install_containers_dir$app_name/$app_name.sh"
        local app_config_file="$install_containers_dir$app_name/$app_name.config"

        # Script updates
        local result=$(sed -i '' -e 's/Template/'"$cap_first_app_name"'/g' "$app_script_file")
        checkSuccess "Update $app_name.sh - all cases of Template to $cap_first_app_name"
        local result=$(sed -i '' -e 's/template/'"$app_name"'/g' "$app_script_file")
        checkSuccess "Update $app_name.sh - all cases of template to $app_name"
        local result=$(sed -i '' -e 's/TEMPLATE/'"$full_caps_app_name"'/g' "$app_script_file")
        checkSuccess "Update $app_name.sh - all cases of TEMPLATE to $full_caps_app_name"
        local result=$(sed -i '' -e 's/old/'"$app_category"'/g' "$app_script_file")
        checkSuccess "Updating $app_name.sh - category to $app_category"
        local result=$(sed -i '' -e 's/It just works!/'"$app_description"'/g' "$app_script_file")
        checkSuccess "Updating $app_name.sh - description to $app_description"

        # Config updates
        local result=$(sed -i '' -e 's/template/'"$app_name"'/g' "$app_config_file")
        checkSuccess "Updating Config - template to $app_name"
        local result=$(sed -i '' -e 's/CFG_TEMPLATE_HOST_NAME=test/CFG_TEMPLATE_HOST_NAME='"$host_name"'/g' "$app_config_file")
        checkSuccess "Updating Config - CFG_TEMPLATE_HOST_NAME to $app_name"

        while true; do
            echo ""
            isQuestion "Would you like to add contents to the docker-compose.yml? (y/n): "
            read -p "" app_docker_compose
            if [[ -n "$app_docker_compose" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$app_docker_compose" == [yY] ]]; then
            sudo $CFG_TEXT_EDITOR "$install_containers_dir$app_name/docker-compose.yml"
        fi
    fi
}