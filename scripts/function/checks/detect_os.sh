#!/bin/bash

detectOS() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        OS_TYPE=""
        OS_VERSION="$VERSION_ID"

        # Check main ID and ID_LIKE to catch derivatives like Pop!_OS
        case "$ID" in
            debian)
                OS_TYPE="Debian"
                ;;
            ubuntu | pop)
                OS_TYPE="Ubuntu"
                ;;
            arch)
                OS_TYPE="Arch"
                ;;
            *)
                if [[ "$ID_LIKE" =~ "debian" ]]; then
                    OS_TYPE="Debian"
                elif [[ "$ID_LIKE" =~ "ubuntu" ]]; then
                    OS_TYPE="Ubuntu"
                else
                    echo "Unsupported OS detected."
                    exit 1
                fi
                ;;
        esac

        echo "Detected OS: $OS_TYPE $OS_VERSION"

        # Check if this is a tested/supported version
        if [[ ("$OS_TYPE" == "Debian" && ! "$OS_VERSION" =~ ^(10|11|12|13)$) || 
              ("$OS_TYPE" == "Ubuntu" && ! "$OS_VERSION" =~ ^(18.04|20.04|22.04)$) ]]; then
            echo "Warning: This OS version ($OS_VERSION) is untested and may not be fully supported."
            while true; do
                read -rp "Do you wish to continue anyway? (y/n): " oswarningaccept
                case "$oswarningaccept" in
                    [Yy]) break ;;
                    [Nn]) exit 1 ;;
                    *) echo "Invalid input. Please enter y or n." ;;
                esac
            done
        fi
    else
        echo "Unable to detect OS."
        exit 1
    fi
}
