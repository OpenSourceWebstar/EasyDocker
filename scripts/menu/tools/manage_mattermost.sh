#!/bin/bash

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
				appMattermostResetUserPassword;
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
