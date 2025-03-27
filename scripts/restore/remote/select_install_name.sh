#!/bin/bash

# Function for the Install Name selection menu
selectRemoteInstallName() 
{
    while true; do
        echo ""
        isNotice "Please select the Install Name : "
        echo ""
        isOption "1. Restore using local $CFG_INSTALL_NAME"
        isOption "2. Specify a different Install Name for restoration"
        echo ""
        isOption "x. Exit"
        echo ""
        isQuestion "Enter your choice: "
        read -rp "" select_option

        case "$select_option" in
            1)
                restore_install_name="$CFG_INSTALL_NAME"
                echo ""
                isNotice "Restoring using Install Name : $restore_install_name"
                echo ""
                ;;
            2)
                echo ""
                isQuestion "Enter the Install Name you would like to restore from: "
                read -rp "" restore_install_name
                isNotice "Restoring using Install Name :  $restore_install_name"
                echo ""
                ;;
            x|X)
                isNotice "Exiting..."
                resetToMenu;
                ;;
            *)
                echo ""
                isNotice "Invalid option. Please select a valid option."
                continue
                ;;
        esac

        break  # Exit the loop when a valid selection is made
    done
}
