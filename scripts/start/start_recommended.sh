#!/bin/bash

installRecommendedApps()
{
    local wireguard_status=$(dockerCheckAppInstalled "wireguard" "docker")
    if [[ "$wireguard_status" != "installed" ]]; then
        echo ""
        echo "####################################################"
        echo "###     Recommended Application - Wireguard      ###"
        echo "####################################################"
        echo ""
        isNotice "It's recommended to install Wireguard upon first install."
        echo ""
        isNotice "Wireguard allows you to access the server via VPN."
        echo ""
        while true; do
            isQuestion "Would you like to Wireguard as per the recommendation? (y/n): "
            read -p "" wireguard_choice
            if [[ -n "$wireguard_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$wireguard_choice" == [yY] ]]; then
            if [[ "$wireguard_status" != "installed" ]]; then
                dockerInstallApp wireguard;
            fi

        elif [[ "$wireguard_choice" == [nN] ]]; then
            break
        fi
    fi

    # Install if keys have been setup
    ssh_new_key=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "ssh_new_key";')
    if [[ "$ssh_new_key" == "true" ]]; then
        echo ""
        echo "####################################################"
        echo "###              SSH Key Downloader              ###"
        echo "####################################################"
        echo ""
        isNotice "As new SSH Keys have been setup, the key downloader app will be installed now..."
        echo ""
        dockerInstallApp sshdownload;
        databaseOptionInsert "ssh_new_key" "false";
    fi

    local traefik_status=$(dockerCheckAppInstalled "traefik" "docker")
    if [[ "$traefik_status" != "installed" ]]; then
        echo ""
        echo "####################################################"
        echo "###      Recommended Application - Traefik       ###"
        echo "####################################################"
        echo ""
        isNotice "It's recommended to install Traefik upon first install."
        echo ""
        isNotice "Traefik secures your Network traffic and automatically installs SSL Certificates"
        echo ""
        while true; do
            isQuestion "Would you like to Traefik as per the recommendation? (y/n): "
            read -p "" recommendation_choice
            if [[ -n "$recommendation_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$recommendation_choice" == [yY] ]]; then
            # Traefik
            if [[ "$traefik_status" != "installed" ]]; then
                dockerInstallApp traefik;
            fi

            isSuccessful "All recommended apps have successfully been set up."
        elif [[ "$recommendation_choice" == [nN] ]]; then
            break
        fi
    fi

    #local general_config_file="$configs_dir$config_file_general"
    #result=$(sudo sed -i "s|CFG_REQUIREMENT_SUGGEST_INSTALLS=true|CFG_REQUIREMENT_SUGGEST_INSTALLS=false|" "$general_config_file")
    #checkSuccess "Disabling install recommendations in the requirements config."
    #isNotice "You can re-enable this in the requirements config file"
    #sourceScanFiles "easydocker_configs";
}
