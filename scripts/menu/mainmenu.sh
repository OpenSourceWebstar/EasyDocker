#!/bin/bash

mainMenu()
{
	createSuccessfulRunFile;

	# We will not show the menu if we are installing Easydocker via the CLI install command
    if [ "$install_via_cli" != "true" ]; then

		# Enable input
		stty echo

		while true; do
			echo ""
			echo "#####################################"
			echo "###         Install Menu          ###"
			echo "#####################################"
			echo ""
			isOption "i. Install Apps"
			#isOption "u. Uninstall Apps"
			isOption "g. Generate App"
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
			status=$(dockerCheckAppInstalled "wireguard" "linux")
			if [ "$status" == "installed" ]; then
				isOption "w. WireGuard"
			fi
			status=$(dockerCheckAppInstalled "ufw" "linux")
			if [ "$status" == "installed" ]; then
				isOption "f. Firewall"
			fi
			isOption "h. Headscale"
			isOption "l. Logs"
			isOption "t. Tools"
			isOption "y. YML Editor"
			echo ""
			isOption "x. Exit"
			echo ""
			isQuestion "What is your choice: "
			read -rp "" choice

			case $choice in
				i)
					while true; do
						showInstructions
						echo ""
						echo "#####################################"
						echo "###         App Categories        ###"
						echo "#####################################"
						echo ""
						for i in "${!app_categories[@]}"; do
        					local capitalized_category=$(echo "${app_categories[$i]}" | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
							isOption "$((i + 1)). ${capitalized_category} Apps"
						done
						echo ""
						isOption "x. Exit"
						echo ""
						isQuestion "Please select an option (1-${#app_categories[@]} or 'x' to exit): "
						read -p "" choice

						# Validate input
						if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#app_categories[@]}" ]; then
							local selected_category="${app_categories[$((choice - 1))]}"
							local capitalized_category=$(echo "${selected_category}" | awk '{print toupper(substr($0, 1, 1)) tolower(substr($0, 2))}')
							echo ""
							echo "#####################################"
							echo "###        ${capitalized_category} Apps"
							echo "#####################################"
							echo ""

							scanCategory "$selected_category"
							startInstall
						elif [[ "$choice" == "x" ]]; then
							isNotice "Exiting..."
							return
						else
							isNotice "Invalid selection. Please choose a valid category or 'x' to exit."
						fi
					done

					;;
				g)
					appGenerate;

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
					isNotice "Invalid choice. Please select a valid option."
					;;
			esac
		done
	else
		isSuccessful "EasyDocker successfully ran."
	fi
}
