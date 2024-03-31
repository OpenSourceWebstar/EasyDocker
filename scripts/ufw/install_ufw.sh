#!/bin/bash

installUFW()
{
   if [[ "$CFG_REQUIREMENT_UFW" == "true" ]]; then
    	ISUFW=$( (sudo ufw status ) 2>&1 )
		if [[ "$ISUFW" == *"command not found"* ]]; then
            echo ""
            echo "##########################################"
            echo "###     Install UFW Firewall           ###"
            echo "##########################################"

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Installing using linux package installer"
            echo ""

            local result=$(yes | sudo apt-get install ufw )
            checkSuccess "Installing UFW package"

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Updating Firewall Rules"
            echo ""

            local result=$(sudo ufw allow 22)
            checkSuccess "Enabling Port 22 through the firewall"
            local result=$(sudo ufw allow ssh)
            checkSuccess "Enabling SSH through the firewall"

            while true; do
                isQuestion "Do you want to keep port 22 (SSH) open? (y/n): "
                read -rp "" UFWSSH
                if [[ "$UFWSSH" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done

            if [[ "$UFWSSH" == [nN] ]]; then
                local result=$(sudo ufw deny 22)
                checkSuccess "Blocking Port 22 through the firewall"
                local result=$(sudo ufw deny ssh)
                checkSuccess "Blocking SSH through the firewall"
            fi

            echo ""
            local result=$(sudo ufw --force enable)
            checkSuccess "Enabling UFW Firewall"

            ((menu_number++))
            echo ""
            echo "---- $menu_number. Changing logging options"
            echo ""

            local result=$(yes | sudo ufw logging $CFG_UFW_LOGGING)
            checkSuccess "Disabling UFW Firewall Logging"

            echo ""
            isSuccessful "UFW Firewall has been installed, you can use ufw status to see the status"

            menu_number=0   
            cd
        fi
    fi
}
