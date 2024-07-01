#!/bin/bash

dockerConfigSetupFileWithData()
{
    local app_name="$1"
    local custom_file="$2"
    local custom_path="$3"

    if [[ $compose_setup == "default" ]]; then
        local file_name="docker-compose.yml";
    elif [[ $compose_setup == "app" ]]; then
        local file_name="docker-compose.$app_name.yml";
    fi

    if [[ $custom_file != "" ]]; then
        local file_name="$custom_file"
    fi

    if [[ $custom_path == "" ]]; then
        local file_path="$containers_dir$app_name"
    elif [[ $custom_path != "" ]]; then
        local file_path="$containers_dir$app_name/$custom_path/"
    fi

    local full_file_path="$file_path/$file_name"

    local result=$(sudo sed -i \
        -e "s|DOMAINNAMEHERE|$domain_full|g" \
        -e "s|DOMAINSUBNAMEHERE|$host_setup|g" \
        -e "s|DOMAINPREFIXHERE|$domain_prefix|g" \
        -e "s|PUBLICIPHERE|$public_ip_v4|g" \
        -e "s|IPADDRESSHERE|$ip_setup|g" \
        -e "s|SUBNETHERE|$CFG_NETWORK_SUBNET|g" \
        -e "s|GATEWAYHERE|${CFG_NETWORK_SUBNET%.*}.1|g" \
        -e "s|PORT1|$usedport1|g" \
        -e "s|PORT2|$usedport2|g" \
        -e "s|PORT3|$usedport3|g" \
        -e "s|PORT4|$usedport4|g" \
        -e "s|PORT5|$usedport5|g" \
        -e "s|PORT6|$usedport6|g" \
        -e "s|PORT7|$usedport7|g" \
        -e "s|PORT8|$usedport8|g" \
        -e "s|PORT9|$usedport9|g" \
        -e "s|TIMEZONEHERE|$CFG_TIMEZONE|g" \
        -e "s|EMAILHERE|$CFG_EMAIL|g" \
        -e "s|DOCKERNETWORK|$CFG_NETWORK_NAME|g" \
        -e "s|MTUHERE|$CFG_NETWORK_MTU|g" \
    "$full_file_path")
    checkSuccess "Updating $file_name for $app_name"
    
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "s|DOCKERINSTALLUSERID|$docker_install_user_id|g" \
            -e "s|#user:|user:|g" \
            -e "s|UIDHERE|$docker_install_user_id|g" \
            -e "s|GIDHERE|$docker_install_user_id|g" \
        "$full_file_path")
        checkSuccess "Updating docker socket for $app_name"
    fi
    
    # Socket updater
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local result=$(sudo sed -i \
            -e "/#SOCKETHERE/s|.*|      - /run/user/${docker_install_user_id}/docker.sock:/run/user/${docker_install_user_id}/docker.sock:ro #SOCKETHERE|" \
        "$full_file_path")
        checkSuccess "Updating docker socket for $app_name"
    elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        local result=$(sudo sed -i \
            -e "/#SOCKETHERE/s|.*|      - $docker_rooted_socket:$docker_rooted_socket:ro #SOCKETHERE|" \
        "$full_file_path")
        checkSuccess "Updating docker socket for $app_name"
    fi

    if [[ $file_name == *"docker-compose"* ]]; then
        if [[ "$public" == "true" ]]; then    
            traefikSetupLabels $app_name $full_file_path;
        fi
        
        if [[ "$public" == "false" ]]; then
            if ! grep -q "#labels:" "$full_file_path"; then
                local result=$(sudo sed -i 's/labels:/#labels:/g' "$full_file_path")
                checkSuccess "Disable Traefik options for private setup"
            fi
            local result=$(sudo sed -i \
                -e "s|0.0.0.0:|127.0.0.1:|g" \
            "$full_file_path")
            checkSuccess "Updating $file_name for $app_name"
        fi

        # Healthcheck updater
        if [[ "$healthcheck" == "false" ]]; then  
            sed -i 's/disable: false #HEALTHCHECKHERE/disable: true #HEALTHCHECKHERE/' "$full_file_path"
        fi
    fi

    scanFileForRandomPassword $full_file_path;
    
    isSuccessful "Updated the $app_name docker-compose.yml"
}