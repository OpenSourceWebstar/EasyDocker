#!/bin/bash

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
