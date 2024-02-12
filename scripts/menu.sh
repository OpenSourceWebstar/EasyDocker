#!/bin/bash

mainMenu()
{
	# Enable input
	stty echo

	while true; do
		echo ""
		echo "#####################################"
		echo "###         Install Menu          ###"
		echo "#####################################"
		echo ""
		isOption "s. System Apps"
		isOption "p. Privacy Apps"
		isOption "u. User Apps"
		isOption "o. Old/Unfinished"
		echo ""
		echo "#####################################"
		echo "###    Backup/Restore/Migrate     ###"
		echo "#####################################"
		echo ""
		isOption "b. Backup"
		isOption "r. Restore"
		isOption "m. Migrate"
		echo ""
		echo "#####################################"
		echo "###          Tools/Other          ###"
		echo "#####################################"
		echo ""
		isOption "c. Configs"
		isOption "d. Database"
		status=$(checkAppInstalled "wireguard" "linux")
        if [ "$status" == "installed" ]; then
			isOption "w. WireGuard"
        fi
		status=$(checkAppInstalled "ufw" "linux")
        if [ "$status" == "installed" ]; then
			isOption "f. Firewall"
        fi
		isOption "h. Headscale"
		isOption "l. Logs"
		isOption "t. Tools"
		isOption "y. YML Editor"
		echo ""
		isOption "i. Initialize"
		isOption "x. Exit"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" choice

		case $choice in
			s)
				showInstallInstructions;

				echo ""				
				echo "#####################################"
				echo "###          System Apps          ###"
				echo "#####################################"
				echo ""

				scanCategory "system"
				startInstall;
				;;
			p)
				showInstallInstructions;

				echo ""
				echo "#####################################"
				echo "###          Privacy Apps         ###"
				echo "#####################################"
				echo ""

				scanCategory "privacy"
				startInstall;
				;;
			u)
				showInstallInstructions;

				echo ""
				echo "#####################################"
				echo "###           User Apps           ###"
				echo "#####################################"
				echo ""

				scanCategory "user"
				startInstall;
				;;
			o)
				showInstallInstructions;

				echo ""
				echo "#####################################"
				echo "###         Old/Unfinished        ###"
				echo "#####################################"
				echo ""

				scanCategory "old"
				startInstall;
				;;
			b)

				echo ""
				echo "#####################################"
				echo "###             Backup            ###"
				echo "#####################################"
				echo ""
				isOptionMenu "Single App Backup - Docker Container Folder (y/n): "
				read -rp "" backupsingle
				isOptionMenu "Full Backup - Docker Folder (y/n): "
				read -rp "" backupfull

				startOther;

				;;
			r)
				echo ""
				echo "#####################################"
				echo "###            Restore            ###"
				echo "#####################################"
				echo ""
   				echo "Please select 'l' for local restore."
    			echo "Please select 'r' for remote restore."
				echo ""
				isOptionMenu "Single Restore - App (l/r): "
				read -rp "" restoresingle
				isOptionMenu "Full Restore - Docker Folder (l/r): "
				read -rp "" restorefull

				startOther;

				;;
			m)
				echo ""
				echo "#####################################"
				echo "###            Migrate            ###"
				echo "#####################################"
				echo ""

				isOptionMenu "Check for Migration file(s) (y/n): "
				read -rp "" migratecheckforfiles
				isOptionMenu "Move files from Migrate folder(s) (y/n): "
				read -rp "" migratemovefrommigrate
				isOptionMenu "Generate Migrate.txt files(s) (y/n): "
				read -rp "" migrategeneratetxt
				isOptionMenu "Scan Folders for Migrate.txt updates (IP/InstallName) (y/n): "
				read -rp "" migratescanforupdates
				isOptionMenu "Scan Folders for Missing Config Values to Migrate.txt (y/n): "
				read -rp "" migratescanforconfigstomigrate
				isOptionMenu "Scan Folders for Migrate.txt updated values to Config (y/n): "
				read -rp "" migratescanformigratetoconfigs

				startOther;
				
				;;

			c)

				viewConfigs;

				;;
			d)
				echo ""
				echo "#####################################"
				echo "###            Database           ###"
				echo "#####################################"
				echo ""
				
				isOptionMenu "View Database Tables & Data? (y/n): "
				read -rp "" toollistalltables
				isOptionMenu "List all apps database? (y/n): "
				read -rp "" toollistallapps
				isOptionMenu "List all installed apps? (y/n): "
				read -rp "" toollistinstalledapps
				isOptionMenu "Update database with installed apps? (y/n): "
				read -rp "" toolupdatedb
				isOptionMenu "Empty a Database Tables? (y/n): "
				read -rp "" toolemptytable
				isOptionMenu "Delete database file? (y/n): "
				read -rp "" tooldeletedb

				startOther;

				;;
			h)
				echo ""
				echo "#####################################"
				echo "###          Headscale            ###"
				echo "#####################################"
				echo ""

				isOptionMenu "Setup Tailscale Client for Localhost? (y/n): "
				read -rp "" headscaleclientlocal
				isOptionMenu "Setup Tailscale Client for a Specific App? (y/n): "
				read -rp "" headscaleclientapp
				isOptionMenu "Create User $CFG_INSTALL_NAME? (y/n): "
				read -rp "" headscaleusercreate
				isOptionMenu "Create API Key for $CFG_INSTALL_NAME? (y/n): "
				read -rp "" headscaleapikeyscreate
				isOptionMenu "List all API Keys? (y/n): "
				read -rp "" headscaleapikeyslist
				isOptionMenu "List all Nodes? (y/n): "
				read -rp "" headscalenodeslist
				isOptionMenu "List all Users? (y/n): "	 
				read -rp "" headscaleuserlist
				isOptionMenu "View Headscale Version? (y/n): "
				read -rp "" headscaleversion
				isOptionMenu "View/Edit Headscale Config File? (y/n): " 
				read -rp "" headscaleconfigfile

				startOther;

				;;

			f)
				echo ""
				echo "#####################################"
				echo "###           Firewall            ###"
				echo "#####################################"
				echo ""

				isOptionMenu "Allow specific port through the firewall? (y/n): "
				read -rp "" firewallallowport
				isOptionMenu "Block specific port through the firewall? (y/n): "
				read -rp "" firewallblockport
				isOptionMenu "Block port 22 (SSH)? (y/n): "
				read -rp "" firewallblock22
				isOptionMenu "Allow port 22 (SSH)? (y/n): "
				read -rp "" firewallallow22
				isOptionMenu "Update logging type for UFW based on Config? (y/n): "
				read -rp "" firewallchangelogging

				startOther;

				;;
			w)
				wireguardManageMenu;

				;;
			l)
				viewLogs;

				;;
			t)
				toolsMenu;

				;;
			y)

				viewComposeFiles;

				;;
			i)
				endStart;

				;;
			x)
				exitScript;

				;;
			*)
				echo "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

toolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###          Tools Menu           ###"
		echo "#####################################"
		echo ""
		isOption "1. Menu - SSH"
		isOption "2. Menu - Docker"
		isOption "3. Menu - Crontab"
		isOption "4. Tool - Reset EasyDocker Git Folder"
		isOption "5. Tool - Force Pre-Installation"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" tools_menu_choice

		case $tools_menu_choice in
			1)
				sshToolsMenu;
				;;
			2)
				dockerToolsMenu;
				;;
			3)
				crontabToolsMenu;
				;;
			4)
				toolsresetgit=y
				startOther;
				;;
			5)
				toolstartpreinstallation=y
				startOther;
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

sshToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###           SSH Menu            ###"
		echo "#####################################"
		echo ""
		isOption "1. Regenerate SSH Key - EasyDocker"
		isOption "2. Regenerate SSH Key - Dockerinstall"
		isOption "3. Setup SSH Keys for Download"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" ssh_menu_choice

		case $ssh_menu_choice in
			1)
				regenerateSSHSetupKeyPair "easydocker";
				;;
			2)
				regenerateSSHSetupKeyPair "dockerinstall";
				;;
			3)
				toolsetupsshkeys=y
				startOther;
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

dockerToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###    Docker Management Menu     ###"
		echo "#####################################"
		echo ""
		isOption "1. Containers - Start/Restart"
		isOption "2. Containers - Stop all"
		isOption "3. Containers - Shutdown all (Root)"
		isOption "4. Containers - Shutdown all (Rootless)"
		isOption "5. Docker - Install Root"
		isOption "6. Docker - Install Rootless"
		isOption "7. Docker - Shutdown Root"
		isOption "8. Docker - Shutdown Rootless"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" docker_menu_choice

		case $docker_menu_choice in
			1)
				toolrestartcontainers=y
				startOther;
				;;
			2)
				toolstopcontainers=y
				startOther;
				;;
			3)
				downAllDockerApps root;
				;;
			4)
				downAllDockerApps rootless;
				;;
			5)
				installDocker;
				;;
			6)
				installDockerRootless;
				;;
			7)
				stopDocker root;
				;;
			8)
				stopDocker rootless;
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

crontabToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###         Crontab Menu          ###"
		echo "#####################################"
		echo ""
		isOption "1. Scan apps for Crontab Backup"
		isOption "2. Force Crontab Reinstall"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" crontab_menu_choice

		case $crontab_menu_choice in
			1)
				toolsstartcrontabsetup=y
				startOther;
				;;
			2)
				toolinstallcrontab=y
				startOther;
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

dashyToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###         Dashy Tools           ###"
		echo "#####################################"
		echo ""
		isOption "1. Run Config Updater"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" dashy_menu_choice

		case $dashy_menu_choice in
			1)
				dashyUpdateConf
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

invidiousToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###         Invidious Tools       ###"
		echo "#####################################"
		echo ""
		isOption "1. Reset a users password"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" invidious_menu_choice

		case $invidious_menu_choice in
			1)
				invidiousResetUserPassword;
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

mattermostToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###        Mattermost Tools       ###"
		echo "#####################################"
		echo ""
		isOption "1. Reset a users password"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" mattermost_menu_choice

		case $mattermost_menu_choice in
			1)
				mattermostResetUserPassword;
				;;
			x)
				endStart;

				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

wireguardManageMenu() 
{
	# Enable input
	stty echo

	while true; do
		echo ""
		echo "#####################################"
		echo "###       Wireguard Manager       ###"
		echo "#####################################"
		echo ""
		echo "Built from: https://github.com/angristan/wireguard-install"
		echo ""
		isOption "1. Add a new user"
		isOption "2. List all users"
		isOption "3. Revoke existing user"
		isOption "4. Uninstall WireGuard"
		isOption "x. Exit"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" wireguard_menu_option

		case "${wireguard_menu_option}" in
			1)
				wireguardNewClient
				;;
			2)
				wireguardListClients
				;;
			3)
				wireguardRevokeClient
				;;
			4)
				wireguardUninstall
				;;
			x)
				resetToMenu;
				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}

menuShowFinalMessages()
{
	local app_name="$1"
	local username="$2"
	local password="$3"
	menuLoginRequired;
	menuPublic;
	menuContinue;
}

menuLoginRequired()
{
	if [[ "$login_required" == "true" ]]; then
		echo ""
		echo "    Website Authentication is setup for $app_name."
		echo ""
		echo "    Your login username is : $CFG_LOGIN_USER"
		echo "    Your password is : $CFG_LOGIN_PASS"
		echo ""
		echo "    (you always find them in the EasyDocker general config under CFG_LOGIN_USER/PASS)"
	fi
	if [[ "$username" != "" ]]; then
		echo ""
		echo "    Application login details are as follows for $app_name."
		echo ""
		echo "    Your login username is : $username"
		echo "    Your password is : $password"
		echo ""
		echo "    (you always find them in the docker-compose file for $app_name)"
	fi
	echo ""
}

menuPublic()
{
	if [[ "$public" == "true" ]]; then
		echo "    Public : https://$host_setup/"
	fi
	echo "    External : http://$public_ip_v4:$usedport1/"
	echo "    Local : http://$ip_setup:$usedport1/"
	echo ""
}

menuContinue()
{
	if [[ "$public" == "CFG_REQUIREMENT_CONTINUE_PROMPT" ]]; then
		while true; do
			isQuestion "Press Enter to continue or press (d) to disable being asked to continue after an app installs."
			read -p "" app_installed_continue
			if [[ -n "$app_installed_continue" ]]; then
				break
			fi
			isNotice "Please provide a valid input."
		done
		if [[ "$app_installed_continue" == [dD] ]]; then
			local config_file="$configs_dir$config_file_requirements"
			result=$(sudo sed -i 's/CFG_REQUIREMENT_CONTINUE_PROMPT=true/CFG_REQUIREMENT_CONTINUE_PROMPT=false/' $config_file)
			checkSuccess "Disabled CFG_REQUIREMENT_CONTINUE_PROMPT in the $config_file_requirements config."
			source $config_file
		fi
	fi
}

scanCategory() 
{
    local category="$1"
    
    for app_dir in "$install_containers_dir"/*/; do
        local app_name=$(basename "$app_dir")
        local app_file="$app_dir$app_name.sh"
        
        if [ -f "$app_file" ]; then
            local category_info=$(grep -Po '(?<=# Category : ).*' "$app_file")
            
            if [ "$category_info" == "$category" ]; then
                local app_description=$(grep -Po '(?<=# Description : ).*' "$app_file")

                # Query the database to check if the app is installed
                results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
                if [[ -n "$results" ]]; then
					local app_description="\e[32m*INSTALLED*\e[0m - $app_description"
				else
					local app_description="\e[33m*NOT INSTALLED*\e[0m - $app_description"
                fi

                isOptionMenu "$app_description "
                read -rp "" $app_name
            fi
        fi
    done
}
