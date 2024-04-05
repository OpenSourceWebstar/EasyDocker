#!/bin/bash

installUFWDocker()
{
    if [[ "$CFG_REQUIREMENT_UFWD" == "true" ]]; then
        if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
            if [[ "$ISUFWD" == *"command not found"* ]]; then
                echo ""
                echo "##########################################"
                echo "###     Install UFW-Docker             ###"
                echo "##########################################"
                
                ((menu_number++))
                echo ""
                echo "---- $menu_number. Installing using linux package installer"
                echo ""

                local ufwpath="/usr/local/bin/ufw-docker"

                local result=$(sudo wget -O $ufwpath https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker > /dev/null 2>&1)
                checkSuccess "Downloading UFW Docker installation files"

                local result=$(sudo rm -rf $script_dir/wget-log)
                checkSuccess "Setting permissions for install files"

                local result=$(sudo chmod +x $ufwpath)
                checkSuccess "Setting permissions for install files"

                local result=$(sudo ufw-docker install > /dev/null 2>&1)
                checkSuccess "Installing UFW Docker"

                local result=$(sudo systemctl restart ufw)
                checkSuccess "Restarting UFW Firewall service"

                isSuccessful "UFW-Docker has been installed, you can use ufw-docker to see the available commands"
                echo ""
                echo ""       
                cd
            fi
        fi
    fi
}
