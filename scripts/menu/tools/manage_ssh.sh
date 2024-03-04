#!/bin/bash

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
