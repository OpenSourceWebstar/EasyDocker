#!/bin/bash

regenerateSSHSetupKeyPair()
{
    local username="$1"

    while true; do
        isQuestion "Are you sure you want to generate new SSH Key(s) for the $username user? (y/n): "
        read -p "" key_regenerate_accept
        case "$key_regenerate_accept" in
            [Yy]*)
                generateSSHKeyPair "$username" "$private_key_path" "$private_key_full" "$public_key_full" reinstall;
                break
                ;;
            [Nn]*)
                # No action needed
                break
                ;;
            *)
                echo "Please enter 'y' or 'n'."
                ;;
        esac
    done
}
