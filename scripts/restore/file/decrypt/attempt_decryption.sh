#!/bin/bash

# Function to attempt decryption with a passphrase
attempt_decryption() 
{
    local passphrase="$1"
    local unzip_path="$2"
    local restore_place="$3"
    local restore_type="$4"
    local password_type="$5"

    case $restore_place in
        local)
            isNotice "Using $password_type to decrypt and unzip (Local $restore_type) for $chosen_backup_file...this may take a while..."
            ;;
        remote)
            isNotice "Using $password_type to decrypt and unzip (Remote $restore_type) $chosen_backup_file...this may take a while..."
            ;;
        migrate)
            isNotice "Using $password_type to decrypt and unzip (Migrate $restore_type) $chosen_backup_file...this may take a while..."
            ;;
    esac

    decryption_success=""
    local success_message_posted=false

    while [[ "$decryption_success" != "false" ]]; do
        local result=$(sudo unzip -o -P "$passphrase" "$chosen_backup_file" -d "$unzip_path" 2>&1)

        if [[ $result == *"incorrect password"* ]]; then
            if [[ $success_message_posted == "false" ]]; then
                isNotice "Decryption and unzip failed due to incorrect password."
                isNotice "Trying another password (if any available)"
                echo ""
                local success_message_posted=true
            fi
            decryption_success=false
            break  # Successful unzip
        fi
        
        if [[ $result == *"inflating"* ]]; then
            if [[ $success_message_posted == "false" ]]; then
                isNotice "Decryption method is successful."
                local success_message_posted=true
            fi
            decryption_success=true
            break  # Successful unzip
        fi
    done

}
