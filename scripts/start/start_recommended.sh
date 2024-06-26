#!/bin/bash

installRecommendedApps()
{
    if [[ $CFG_REQUIREMENT_SUGGEST_INSTALLS == "true" ]]; then
        local wireguard_status=$(dockerCheckAppInstalled "wireguard" "docker")
        if [[ $CFG_REQUIREMENT_SSHKEY_DOWNLOADER == "true" ]]; then
            local sshdownload_status=$(dockerCheckAppInstalled "sshdownload" "docker")
        else
            local sshdownload_status="installed"
        fi
        local traefik_status=$(dockerCheckAppInstalled "traefik" "docker")

        if [ "$wireguard_status" != "installed" ] || \
        [ "$sshdownload_status" != "installed" ] || \
        [ "$traefik_status" != "installed" ]; then
            echo ""
            echo "####################################################"
            echo "###           Recommended Applications           ###"
            echo "####################################################"
            echo ""
            isNotice "There are recommended applications available to install."
            echo ""
            while true; do
                isQuestion "Would you like to follow the recommended app installation process? (y/n): "
                read -p "" default_recommendation_choice
                if [[ -n "$default_recommendation_choice" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done

            if [[ "$default_recommendation_choice" == [nN] ]]; then
                while true; do
                    isQuestion "Would you like to stop being asked to install the recommended applications? (y/n): "
                    read -p "" disable_recommended_apps
                    if [[ -n "$disable_recommended_apps" ]]; then
                        break
                    fi
                    isNotice "Please provide a valid input."
                done
                if [[ "$disable_recommended_apps" == [yY] ]]; then
                    local requirements_config_file="$configs_dir$config_file_requirements"
                    result=$(sudo sed -i "s|CFG_REQUIREMENT_SUGGEST_INSTALLS=true|CFG_REQUIREMENT_SUGGEST_INSTALLS=false|" "$requirements_config_file")
                    checkSuccess "Disabling install recommendations in the requirements config."
                    isNotice "You can re-enable this in the requirements config file"
                    sourceScanFiles "easydocker_configs";
                elif [[ "$disable_recommended_apps" == [nN] ]]; then
                    isSuccessful "You will be asked to install the recommended applications upon loading EasyDocker again."
                fi

            elif [[ "$default_recommendation_choice" == [yY] ]]; then

                # List of applications available for install
                # Wireguard

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
                        read -p "" wireguard_recommendation_choice
                        if [[ -n "$wireguard_recommendation_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$wireguard_recommendation_choice" == [yY] ]]; then
                        dockerInstallApp wireguard;
                    fi
                fi

                # SSHdownload
                local ssh_new_key=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "ssh_new_key";')
                if [[ "$sshdownload_status" != "installed" ]]; then
                    if [[ "$ssh_new_key" == "true" ]]; then
                        echo ""
                        echo "####################################################"
                        echo "###              SSH Key Downloader              ###"
                        echo "####################################################"
                        echo ""
                        isNotice "New SSH Keys have been setup and installed on the system."
                        isNotice "The SSH Key downloader has not been setup to download the installed keys."
                        echo ""
                        while true; do
                            isQuestion "Would you like to install the SSH Key Downloader as per the recommendation? (y/n): "
                            read -p "" sshdownload_recommendation_choice
                            if [[ -n "$sshdownload_recommendation_choice" ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input."
                        done
                        if [[ "$sshdownload_recommendation_choice" == [yY] ]]; then
                            dockerInstallApp sshdownload;
                            databaseOptionInsert "ssh_new_key" "false";
                        fi
                    else
                        echo ""
                        echo "####################################################"
                        echo "###              SSH Key Downloader              ###"
                        echo "####################################################"
                        echo ""
                        isNotice "The SSH Key downloader has not been found on your system."
                        isNotice "You may not need to install this if you have already downloaded all of your keys."
                        isNotice "You can disable being asked to install this in the future if you select the 'n' option"
                        echo ""
                        while true; do
                            isQuestion "Would you like to install the SSH Key Downloader as per the recommendation? (y/n): "
                            read -p "" sshdownload_recommendation_choice
                            if [[ -n "$sshdownload_recommendation_choice" ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input."
                        done
                        if [[ "$sshdownload_recommendation_choice" == [yY] ]]; then
                            dockerInstallApp sshdownload;
                            databaseOptionInsert "ssh_new_key" "false";
                        elif [[ "$sshdownload_recommendation_choice" == [nN] ]]; then
                            while true; do
                                isQuestion "Would you like to stop being asked to install the SSH Key Downloader? (y/n): "
                                read -p "" disable_recommended_apps
                                if [[ -n "$disable_recommended_apps" ]]; then
                                    break
                                fi
                                isNotice "Please provide a valid input."
                            done
                            if [[ "$disable_recommended_apps" == [yY] ]]; then
                                local requirements_config_file="$configs_dir$config_file_requirements"
                                result=$(sudo sed -i "s|CFG_REQUIREMENT_SSHKEY_DOWNLOADER=true|CFG_REQUIREMENT_SSHKEY_DOWNLOADER=false|" "$requirements_config_file")
                                checkSuccess "Disabling SSH Key Downloader in the requirements config."
                                isNotice "You can re-enable this in the requirements config file"
                                sourceScanFiles "easydocker_configs";
                            elif [[ "$disable_recommended_apps" == [nN] ]]; then
                                isSuccessful "You will be asked to install the recommended applications upon loading EasyDocker again."
                            fi
                        fi
                    fi
                fi
                
                # Traefik
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
                        read -p "" traefik_recommendation_choice
                        if [[ -n "$traefik_recommendation_choice" ]]; then
                            break
                        fi
                        isNotice "Please provide a valid input."
                    done
                    if [[ "$traefik_recommendation_choice" == [yY] ]]; then
                        dockerInstallApp traefik;
                    fi
                fi

                isSuccessful "All recommended apps have successfully been set up."
            fi
        fi
    fi
}
