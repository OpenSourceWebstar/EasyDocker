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
                read -r "" UFWSSH
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

installUFWDocker()
{
    if [[ "$CFG_REQUIREMENT_UFWD" == "true" ]]; then
        if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "false" ]]; then
            if [[ "$ISUFWD" == *"command not found"* ]]; then
                echo ""
                echo "##########################################"
                echo "###     Install UFW-Docker             ###"
                echo "##########################################"
                echo ""
                echo "---- $menu_number. Installing using linux package installer"
                echo ""

                local result=$(sudo -u $sudo_user_name wget -O /usr/local/bin/ufw-docker https://github.com/chaifeng/ufw-docker/raw/master/ufw-docker)
                checkSuccess "Downloading UFW Docker installation files"

                local result=$(sudo chmod +x /usr/local/bin/ufw-docker)
                checkSuccess "Setting permissions for install files"

                local result=$(sudo ufw-docker install)
                checkSuccess "Installing UFW Docker"

                local result=$(sudo -u $sudo_user_name systemctl restart ufw)
                checkSuccess "Restarting UFW Firewall service"

                echo "---- $menu_number. UFW-Docker has been installed, you can use ufw-docker to see the available commands"
                echo ""
                echo ""       
                cd
            fi
        fi
    fi
}
