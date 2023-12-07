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
			l)
				viewLogs;

				;;
			t)
				echo ""
				echo "#####################################"
				echo "###             Tools             ###"
				echo "#####################################"
				echo ""

				isOptionMenu "Setup SSH Keys for Download (y/n): "
				read -rp "" toolsetupsshkeys
				isOptionMenu "Reset EasyDocker Git Folder (y/n): "
				read -rp "" toolsresetgit
				isOptionMenu "Start Pre-Installation (y/n): "
				read -rp "" toolstartpreinstallation
				isOptionMenu "Start/Restart all docker containers? (y/n): "
				read -rp "" toolrestartcontainers
				isOptionMenu "Stop all docker containers? (y/n): "
				read -rp "" toolstopcontainers
				isOptionMenu "Scan apps for Crontab Backup? (y/n): "
				read -rp "" toolsstartcrontabsetup
				isOptionMenu "Install Crontab? (y/n): "
				read -rp "" toolinstallcrontab
				#isOptionMenu "Remove Docker Manager User from this PC? (y/n): "
				#read -rp "" toolsremovedockermanageruser
				#isOptionMenu "Install Docker Manager User on this PC? (y/n): "
				#read -rp "" toolsinstalldockermanageruser
				#isOptionMenu "Install Remote SSH Keys? (y/n): "
				#read -rp "" toolinstallremotesshlist
				#isOptionMenu "Install SSH Scanning into Crontab? (y/n): "
				#read -rp "" toolinstallcrontabssh

				startOther;

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

menuShowFinalMessages()
{
	menuLoginRequired;
	menuPublic;
	menuContinue;
}

menuLoginRequired()
{
	if [[ "$login_required" == "true" ]]; then
		echo ""
		echo "    Authentication is setup for $app_name."
		echo ""
		echo "    Your login username is : $CFG_LOGIN_USER"
		echo "    Your password is : $CFG_LOGIN_PASS"
		echo ""
		echo "    (you always find them in the EasyDocker general config under CFG_LOGIN_USER/PASS)"
	fi
	echo ""
}

menuPublic()
{
	if [[ "$public" == "true" ]]; then
		echo "    Public : https://$host_setup/"
	fi
	echo "    External : http://$public_ip:$usedport1/"
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
		echo ""
		isQuestion "What is your choice: "
		read -rp "" choice

		case $choice in
			1)
				dashyUpdateConf
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
		echo ""
		isQuestion "What is your choice: "
		read -rp "" choice

		case $choice in
			1)
				invidiousResetUserPassword;
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