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
            isQuestion "Please enter the name of the application you would like to create a script for: "
            read -p "" app_name
        fi

        if [[ -d "$install_containers_dir$app_name" ]]; then
            isError "A folder with that name already exists. Please choose another name."
            app_name=""  # Reset app_name to prompt for a new input
        elif echo "$app_name" | grep -q '[0-9\s]'; then
            isError "The application name cannot contain any numbers or spaces. Please choose another name."
            app_name=""  # Reset app_name to prompt for a new input
        else
            isSuccessful "Valid application name given."
            cap_first_app_name=$(echo "$app_name" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
            full_caps_app_name=$(echo "$app_name" | awk '{print toupper($0)}')
            echo ""
            break
        fi
        echo "Please provide a valid app name."
    done

    while true; do
        isQuestion "Please enter the hostname (e.g., a hostname 'test' would set up the domain: test.yourdomain.com): "
        read -p "" host_name

        # Check if host_name is contained in the file
        if grep -q "^${host_name}$" "$configs_dir$ip_file"; then
            isError "A hostname with that name already exists. Please choose another name."
            while true; do
                echo "Do you want to (c)ontinue with this hostname, (e)nter a new one, or (x) exit? (c/e/x):"
                read -p "" choice
                case $choice in
                    [Cc]* ) 
                        break 2  # Break out of both loops to continue with the existing hostname
                        ;;
                    [Ee]* ) 
                        host_name=""  # Reset host_name to prompt for a new input
                        break  # Break out of the inner loop to prompt for a new hostname
                        ;;
                    [Xx]* ) 
                        isNotice "Exiting..."
                        resetToMenu;
                        ;;
                    * ) 
                        echo "Please answer c, e, or x."
                        ;;
                esac
            done
        else
            if [[ -n "$host_name" ]]; then
                break  # Exit the loop if host_name is valid and not found in the file
            else
                isNotice "Please provide a valid hostname"
            fi
        fi
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
        echo ""
        isNotice "Please select the application category:"
        echo ""
        for i in "${!app_categories[@]}"; do
            local capitalized_category=$(echo "${app_categories[$i]}" | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
            isOption "$((i + 1)). ${capitalized_category} App"
        done
        echo ""
        isQuestion "Enter your choice (1-${#app_categories[@]}): "
        read -rp "" app_selection
        echo ""

        # Validate input
        if [[ "$app_selection" =~ ^[1-9][0-9]*$ ]] && [ "$app_selection" -le "${#app_categories[@]}" ]; then
            local selected_category="${app_categories[$((app_selection - 1))]}"
            isNotice "Application will be set to a ${selected_category^} App"
            app_category=$selected_category
            break
        else
            isNotice "Invalid choice. Please enter a number between '1' and '${#app_categories[@]}'."
        fi
    done

    if [[ ! -d "$install_containers_dir$app_name" ]]; then

        local app_script_file="$install_containers_dir$app_name/$app_name.sh"
        local app_config_file="$install_containers_dir$app_name/$app_name.config"

        local result=$(createFolders "loud" $docker_install_user $install_containers_dir$app_name)
        checkSuccess "Creating new folder named $app_name"
        local result=$(sudo cp -r $install_containers_dir/template/* $install_containers_dir$app_name)
        checkSuccess "Copying template files to the $app_name folder"
        local result=$(sudo mv $install_containers_dir$app_name/template.sh "$app_script_file")
        checkSuccess "Renaming script file for $app_name"
        local result=$(sudo mv $install_containers_dir$app_name/template.config "$app_config_file")
        checkSuccess "Renaming config file for $app_name"

        # Script updates
        local result=$(sudo sed -i '' -e 's/Template/'"$cap_first_app_name"'/g' "$app_script_file" > /dev/null 2>&1)
        checkSuccess "Update $app_name.sh - all cases of Template to $cap_first_app_name"
        local result=$(sudo sed -i '' -e 's/template/'"$app_name"'/g' "$app_script_file" > /dev/null 2>&1)
        checkSuccess "Update $app_name.sh - all cases of template to $app_name"
        local result=$(sudo sed -i '' -e 's/TEMPLATE/'"$full_caps_app_name"'/g' "$app_script_file" > /dev/null 2>&1)
        checkSuccess "Update $app_name.sh - all cases of TEMPLATE to $full_caps_app_name"
        local result=$(sudo sed -i '' -e 's/old/'"$app_category"'/g' "$app_script_file" > /dev/null 2>&1)
        checkSuccess "Updating $app_name.sh - category to $app_category"
        local result=$(sudo sed -i '' -e 's/It just works!/'"$app_description"'/g' "$app_script_file" > /dev/null 2>&1)
        checkSuccess "Updating $app_name.sh - description to $app_description"

        # Config updates
        local result=$(sudo sed -i '' -e 's/Template/'"$cap_first_app_name"'/g' "$app_config_file" > /dev/null 2>&1)
        checkSuccess "Update $app_name.config - all cases of Template to $cap_first_app_name"
        local result=$(sudo sed -i '' -e 's/template/'"$app_name"'/g' "$app_config_file" > /dev/null 2>&1)
        checkSuccess "Update $app_name.config - all cases of template to $app_name"
        local result=$(sudo sed -i '' -e 's/TEMPLATE/'"$full_caps_app_name"'/g' "$app_config_file" > /dev/null 2>&1)
        checkSuccess "Update $app_name.config - all cases of TEMPLATE to $full_caps_app_name"
        local result=$(sudo sed -i '' -e 's/CFG_TEMPLATE_HOST_NAME=test/CFG_TEMPLATE_HOST_NAME='"$host_name"'/g' "$app_config_file" > /dev/null 2>&1)
        checkSuccess "Updating Config - CFG_TEMPLATE_HOST_NAME to $app_name"

        # Hostfile addition
        hostfile_last_ip=$(tail -n 1 "$configs_dir$ip_file" | awk '{print $2}')
        # Increment the last octet of the IP address
        IFS='.' read -r -a ip_parts <<< "$hostfile_last_ip"
        hostfile_new_ip="${ip_parts[0]}.${ip_parts[1]}.${ip_parts[2]}.$((ip_parts[3] + 1))"
        # Append the new entry to the file
        echo "$host_name $hostfile_new_ip" >> "$install_configs_dir$ip_file"
        checkSuccess "Add the new entry to ips_hostname file."
        checkEasyDockerConfigFilesMissingVariables;

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

        while true; do
            echo ""
            isQuestion "Would you like to edit the $app_name.config? (y/n): "
            read -p "" app_config
            if [[ -n "$app_config" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$app_config" == [yY] ]]; then
            sudo $CFG_TEXT_EDITOR "$install_containers_dir$app_name/$app_name.config"
        fi

        while true; do
            echo ""
            isQuestion "Would you like to edit the $app_name.sh install script? (y/n): "
            read -p "" app_script
            if [[ -n "$app_script" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$app_script" == [yY] ]]; then
            sudo $CFG_TEXT_EDITOR "$install_containers_dir$app_name/$app_name.sh"
        fi

        while true; do
            echo ""
            isQuestion "Would you like to install $app_name? (y/n): "
            read -p "" app_install
            if [[ -n "$app_install" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$app_install" == [yY] ]]; then
            dockerInstallApp $app_name
        fi
    fi
}