#!/bin/bash

linkdingToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###        Linkding Tools         ###"
		echo "#####################################"
		echo ""
		isOption "1. Run Config Updater"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" linkding_menu_choice

		case $linkding_menu_choice in
			1)
				appLinkdingSetupUser;
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
