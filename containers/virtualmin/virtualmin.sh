#!/bin/bash

# Category : system
# Description : Virtualmin Proxy - *Requires Virtualmin* (c/u/s/r/i):

installVirtualmin()
{
    local passedValue="$1"

    if [[ "$passedValue" == "install" ]]; then
        virtualmin=i
    fi

    if [[ "$virtualmin" == *[cCtTuUsSrRiI]* ]]; then
        setupConfigToContainer --silent virtualmin;
        local app_name=$CFG_VIRTUALMIN_APP_NAME
        setupInstallVariables $app_name;
    fi
    
    if [[ "$virtualmin" == *[cC]* ]]; then
        editAppConfig $app_name;
    fi

    if [[ "$virtualmin" == *[uU]* ]]; then
        uninstallApp $app_name;
    fi

    if [[ "$virtualmin" == *[sS]* ]]; then
        shutdownApp $app_name;
    fi

    if [[ "$virtualmin" == *[rR]* ]]; then
        if [[ $compose_setup == "default" ]]; then
            dockerDownUpDefault $app_name;
        elif [[ $compose_setup == "app" ]]; then
            dockerDownUpAdditionalYML $app_name;
        fi
    fi
    
    if [[ "$virtualmin" == *[iI]* ]]; then
        if [[ "$OS" == [1234567] ]]; then
            ISVIRTUALMIN=$( (sudo systemctl status webmin) 2>&1 )
            if [[ "$ISVIRTUALMIN" == *"could not be found."* ]]; then
                isSuccessful "Virtualmin is installed on this sytem...continuing..."
                if isAppInstalled "traefik"; then
                    echo ""
                    echo "##########################################"
                    echo "###          Install $app_name"
                    echo "##########################################"
                    echo ""

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Setting up install folder and config file for $app_name."
                    echo ""

                    setupConfigToContainer $app_name install;
                    isSuccessful "Install folders and Config files have been setup for $app_name."

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Checking & Opening ports if required"
                    echo ""

                    checkAppPorts $app_name install;
                    if [[ $disallow_used_port == "true" ]]; then
                        isError "A used port conflict has occured, setup is cancelling..."
                        disallow_used_port=""
                        return
                    fi
                    if [[ $disallow_open_port == "true" ]]; then
                        isError "An open port conflict has occured, setup is cancelling..."
                        disallow_open_port=""
                        return
                    fi
        
                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Pulling a default $app_name docker-compose.yml file."
                    echo ""

                    if [[ $compose_setup == "default" ]]; then
                        setupComposeFileNoApp $app_name;
                    elif [[ $compose_setup == "app" ]]; then
                        setupComposeFileApp $app_name;
                    fi

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Making edits to the Virtualmin system files."
                    echo ""

                    local miniserv_conf="/etc/webmin/miniserv.conf"
                    local config_conf="/etc/webmin/config"

                    if [[ -f "$miniserv_conf" ]]; then
                        if ! grep -q "^ssl=0" "$miniserv_conf"; then
                            echo "ssl=0" | sudo tee -a "$miniserv_conf"
                        fi

                        if ! grep -q "^redirect_host=$domain_full" "$miniserv_conf"; then
                            echo "redirect_host=$domain_full" | sudo tee -a "$miniserv_conf"
                        fi

                        if ! grep -q "^redirect_port=443" "$miniserv_conf"; then
                            echo "redirect_port=443" | sudo tee -a "$miniserv_conf"
                        fi
                    fi

                    if [[ -f "$config_conf" ]]; then
                        if ! grep -q "^referers=$domain_full" "$config_conf"; then
                            echo "referers=$domain_full" | sudo tee -a "$config_conf"
                        fi
                    fi

                    local result=$(sudo systemctl restart webmin)
                    checkSuccess "Restarting Webmin."
                    local result=$(sudo systemctl restart virtualmin)  
                    checkSuccess "Restarting Virtualmin."

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Updating file permissions before starting."
                    echo ""

                    fixPermissionsBeforeStart $app_name;

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Running the docker-compose.yml to Install $app_name"
                    echo ""

                    whitelistAndStartApp $app_name install;

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. Adding $app_name to the Apps Database table."
                    echo ""

                    databaseInstallApp $app_name;

                    ((menu_number++))
                    echo ""
                    echo "---- $menu_number. You can find $app_name files at $containers_dir$app_name"
                    echo ""
                    echo "    You can now navigate to your $app_name service using any of the options below : "
                    echo ""
                    echo "    Public : https://$host_setup/"
                    echo "    External : http://$public_ip:$port/"
                    echo "    Local : http://$ip_setup:$port/"
                    echo ""    
                    menu_number=0
                    sleep 3s
                    cd
                fi
                virtualmin=n
            else
                isNotice "Traefik is not installed on this sytem..."
                isNotice "Please install Traefik and try agin..."
                sleep 10
            fi
        fi
    fi
}
