#!/bin/bash

installRecommendedApps()
{
    # Install if keys have been setup
    if [[ "$ssh_new_key" == "true" ]]; then
        echo ""
        echo "####################################################"
        echo "###              SSH Key Downloader              ###"
        echo "####################################################"
        echo ""
        isNotice "As new SSH Keys have been setup, the key download app will be installed now..."
        echo ""
        dockerInstallApp sshdownload;
    fi
    local traefik_status=$(dockerCheckAppInstalled "traefik" "docker")
    if [[ "$traefik_status" != "installed" ]]; then
        echo ""
        echo "####################################################"
        echo "###           Recommended Applications           ###"
        echo "####################################################"
        echo ""
        isNotice "It's recommended to install Traefik upon first install."
        echo ""
        isNotice "Traefik secures your Network traffic and automatically installs SSL Certificates"
        echo ""
        while true; do
            isQuestion "Would you like to follow the recommendations? (y/n): "
            read -p "" recommendation_choice
            if [[ -n "$recommendation_choice" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        if [[ "$recommendation_choice" == [yY] ]]; then
            # Traefik
            if [[ "$traefik_status" != "installed" ]]; then
                traefik=i
                installTraefik;
            fi

            isSuccessful "All recommended apps have successfully been set up."
        elif [[ "$recommendation_choice" == [nN] ]]; then
            local general_config_file="$configs_dir$config_file_general"
            result=$(sudo sed -i "s|CFG_REQUIREMENT_SUGGEST_INSTALLS=true|CFG_REQUIREMENT_SUGGEST_INSTALLS=false|" "$general_config_file")
            checkSuccess "Disabling install recommendations in the requirements config."
            isNotice "You can re-enable this in the requirements config file"
            sourceScanFiles "easydocker_configs";
        fi
    fi
}
