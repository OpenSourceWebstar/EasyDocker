#!/bin/bash

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
				appInvidiousResetUserPassword;
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
