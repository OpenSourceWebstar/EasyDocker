#!/bin/bash

installUFW()
{
   if [[ "$CFG_REQUIREMENT_UFW" == "true" ]]; then
    	ISUFW=$( (ufw status ) 2>&1 )
		if [[ "$ISUFW" == *"command not found"* ]]; then
            echo ""
            echo "##########################################"
            echo "###     Install UFW Firewall           ###"
            echo "##########################################"
            echo ""
            echo "---- $menu_number. Installing using linux package installer"
            echo ""

            result=$(yes | sudo apt-get install ufw )
            checkSuccess "Installing UFW package"

            while true; do
                isQuestion "Do you want to allow port 22 (SSH) through the firewall? (y/n): "
                read -rp "" UFWSSH
                if [[ "$UFWSSH" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done

            if [[ "$UFWSSH" == "yY" ]]; then
                result=$(sudo ufw allow ssh --force)
                checkSuccess "Enabling SSH through the firewall"
            fi

            result=$(sudo ufw --force enable)
            checkSuccess "Enabling UFW Firewall"
            
            # UFW Logging rules : https://linuxhandbook.com/ufw-logs/
            while true; do
                isQuestion "Do you want to disable logging for privacy? (y/n): "
                read -rp "" UFWP
                if [[ "$UFWP" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done            
            if [[ "$UFWP" == "yY" ]]; then
                result=$(yes | sudo ufw logging off)
                checkSuccess "Disabling UFW Firewall Logging"	
            fi
            
            if [[ "$UFWP" == "nN" ]]; then
                result=$(yes | sudo ufw logging medium)
                checkSuccess "Enabling UFW Firewall Logging"	
            fi

            echo ""
            echo "---- $menu_number. UFW has been installed, you can use ufw status to see the status"
            echo "    NOTE - The UFW-Docker package is NEEDED as docker ignores the UFW Firewall"
            echo ""       
            cd
        fi
    fi
}

installUFWDocker()
{
    if [[ "$CFG_REQUIREMENT_UFWD" == "true" ]]; then
		if [[ "$ISUFWD" == *"command not found"* ]]; then
            echo ""
            echo "##########################################"
            echo "###     Install UFW-Docker             ###"
            echo "##########################################"
            echo ""
            echo "---- $menu_number. Installing using linux package installer"
            echo ""

            result=$(sudo wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker)
            checkSuccess "Downloading UFW Docker installation files"

            result=$(sudo chmod +x /usr/local/bin/ufw-docker)
            checkSuccess "Setting permissions for install files"

            result=$(sudo ufw-docker install)
            checkSuccess "Installing UFW Docker"

            result=$(sudo systemctl restart ufw)
            checkSuccess "Restarting UFW Firewall service"

            echo "---- $menu_number. UFW-Docker has been installed, you can use ufw-docker to see the available commands"
            echo ""
            echo ""       
            cd
        fi
    fi
}