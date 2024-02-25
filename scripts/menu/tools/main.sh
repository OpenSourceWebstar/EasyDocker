#!/bin/bash

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
