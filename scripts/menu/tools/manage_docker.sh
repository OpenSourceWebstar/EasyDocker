#!/bin/bash

dockerToolsMenu()
{
	# Enable input
	stty echo
	
	while true; do
		echo ""
		echo "#####################################"
		echo "###    Docker Management Menu     ###"
		echo "#####################################"
		echo ""
		isOption "1. Containers - Start/Restart"
		isOption "2. Containers - Stop all"
		isOption "3. Containers - Shutdown all (Root)"
		isOption "4. Containers - Shutdown all (Rootless)"
		isOption "5. Docker - Install Root"
		isOption "6. Docker - Install Rootless"
		isOption "7. Docker - Shutdown Root"
		isOption "8. Docker - Shutdown Rootless"
		isOption "x. Exit to Main Menu"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" docker_menu_choice

		case $docker_menu_choice in
			1)
				toolrestartcontainers=y
				startOther;
				;;
			2)
				toolstopcontainers=y
				startOther;
				;;
			3)
				downAllDockerApps root;
				;;
			4)
				downAllDockerApps rootless;
				;;
			5)
				installDocker;
				;;
			6)
				installDockerRootless;
				;;
			7)
				stopDocker root;
				;;
			8)
				stopDocker rootless;
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
