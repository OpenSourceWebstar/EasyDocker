#!/bin/bash

detectOS()
{
    local flag="$1"

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        case "$NAME" in
            "Debian GNU/Linux")
                case "$VERSION_ID" in
                    "10")
                        detected_os="Debian 10"
                        OS=1
                        ;;
                    "11")
                        detected_os="Debian 11"
                        OS=2
                        ;;
                    "12")
                        detected_os="Debian 12"
                        OS=3
                        ;;
                    *)
                        detected_os="Debian (Unknown Version)"
                        OS=4
                        ;;
                esac
                ;;
            "Ubuntu")
                case "$VERSION_ID" in
                    "18.04")
                        detected_os="Ubuntu 18.04"
                        OS=5
                        ;;
                    "20.04" | "21.04" | "22.04")
                        detected_os="Ubuntu 20.04 / 21.04 / 22.04"
                        OS=6
                        ;;
                    *)
                        detected_os="Ubuntu (Unknown Version)"
                        OS=7
                        ;;
                esac
                ;;
            "Arch Linux")
                detected_os="Arch Linux"
                OS=8
                ;;
            *)  # Default selection (End this Installer)
                echo "Unable to detect OS."
                exit 1
                ;;
        esac
        
        echo ""
        checkSuccess "Detected OS: $detected_os"
        
        if [ "$OS" -gt 3 ]; then
            isError "This OS ($detected_os) is untested and may not be fully supported."
            while true; do
                isQuestion "Do you wish to continue anyway? (y/n): "
                read -rp "" oswarningaccept
                if [[ -n "$oswarningaccept" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
        fi
    else
        checkSuccess "Unable to detect OS."
        exit 1
    fi
}
