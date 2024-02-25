#!/bin/bash

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
				appDashyUpdateConf
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
