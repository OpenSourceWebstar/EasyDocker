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
		isOption "d. Database"
		isOption "c. Configs"
		isOption "l. Logs"
		isOption "t. Tools"
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
				
				;;
			p)
				showInstallInstructions;

				echo ""
				echo "#####################################"
				echo "###          Privacy Apps         ###"
				echo "#####################################"
				echo ""

				scanCategory "privacy"
				
				;;
			u)
				showInstallInstructions;

				echo ""
				echo "#####################################"
				echo "###           User Apps           ###"
				echo "#####################################"
				echo ""

				scanCategory "user"

				;;
			o)
				showInstallInstructions;

				echo ""
				echo "#####################################"
				echo "###         Old/Unfinished        ###"
				echo "#####################################"
				echo ""

				scanCategory "old"

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

			t)
				echo ""
				echo "#####################################"
				echo "###             Tools             ###"
				echo "#####################################"
				echo ""
				isOptionMenu "Reset EasyDocker Git Folder (y/n): "
				read -rp "" toolsresetgit
				isOptionMenu "Start Pre-Installation (y/n): "
				read -rp "" toolstartpreinstallation
				isOptionMenu "Start Crontab Installation? (y/n): "
				read -rp "" toolsstartcrontabsetup
				isOptionMenu "Start/Restart all docker containers? (y/n): "
				read -rp "" toolrestartcontainers
				isOptionMenu "Stop all docker containers? (y/n): "
				read -rp "" toolstopcontainers
				isOptionMenu "Remove Docker Manager User from this PC? (y/n): "
				read -rp "" toolsremovedockermanageruser
				isOptionMenu "Install Docker Manager User on this PC? (y/n): "
				read -rp "" toolsinstalldockermanageruser
				isOptionMenu "Install Remote SSH Keys? (y/n): "
				read -rp "" toolinstallremotesshlist
				isOptionMenu "Install Crontab? (y/n): "
				read -rp "" toolinstallcrontab
				isOptionMenu "Install SSH Scanning into Crontab? (y/n): "
				read -rp "" toolinstallcrontabssh

				startOther;

				;;
			c)

				viewConfigs;

				;;
			l)
				viewLogs;

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

# Function to scan for apps in a specific category
scanCategory() 
{
    local category="$1"
    local category_dir="$containers_dir/$category"

    for app_dir in "$category_dir"/*; do
        if [ -d "$app_dir" ]; then
			local app_name=$(basename "$app_dir")
			local install_file="$app_dir/install.sh"
            local app_description=$(grep -Po '(?<=# Description : ).*' "$install_file")

            isOptionMenu "$app_description (u/s/r/i): "
			read -rp "" $app_name
			startInstall;
        fi
    done
}