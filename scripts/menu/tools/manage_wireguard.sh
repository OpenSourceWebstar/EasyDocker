#!/bin/bash

wireguardManageMenu() 
{
	# Enable input
	stty echo

	while true; do
		echo ""
		echo "#####################################"
		echo "###       Wireguard Manager       ###"
		echo "#####################################"
		echo ""
		echo "Built from: https://github.com/angristan/wireguard-install"
		echo ""
		isOption "1. Add a new user"
		isOption "2. List all users"
		isOption "3. Revoke existing user"
		isOption "4. Uninstall WireGuard"
		isOption "x. Exit"
		echo ""
		isQuestion "What is your choice: "
		read -rp "" wireguard_menu_option

		case "${wireguard_menu_option}" in
			1)
				wireguardNewClient
				;;
			2)
				wireguardListClients
				;;
			3)
				wireguardRevokeClient
				;;
			4)
				wireguardUninstall
				;;
			x)
				resetToMenu;
				;;
			*)
				isNotice "Invalid choice. Please select a valid option."
				;;
		esac
	done
}
