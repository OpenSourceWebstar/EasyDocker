#!/bin/bash

restoreExtractFile()
{
    cd $RESTORE_SAVE_DIRECTORY

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
            # Use pv with the file size for progress monitoring
            local result=$(sudo unzip -o -P "$passphrase" -d "$unzip_path" 2>&1)

            if [[ $result == *"incorrect password"* ]]; then
                if [[ $success_message_posted == "false" ]]; then
                    isNotice "Decryption and unzip failed due to incorrect password."
                    isNotice "Trying another password (if any available)"
                    echo ""
                    local success_message_posted=true
                fi
                decryption_success=false
                break  # Break on failure due to incorrect password
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

    # Function to prompt for passphrase
    prompt_for_passphrase() 
    {
        isQuestion "Enter the passphrase for $chosen_backup_file or 'x' to exit: "
        read -s -r passphrase

        if [ "$passphrase" = "x" ]; then
            isNotice "Exiting..."
            exit 1
        fi
    }

    # Full (Local or Remote)
    if [[ "$restorefull" == [lLrR] ]]; then

        # Full Specific
        local restore_type="full"
        if [[ "$restorefull" == [lL] ]]; then
            local restore_place="local"
        elif [[ "$restorefull" == [rR] ]]; then
            local restore_place="remote"
        fi
    
        if [ -n "$CFG_BACKUP_PASSPHRASE" ]; then
            attempt_decryption "$CFG_BACKUP_PASSPHRASE" "/" "$restore_place" "$restore_type" "CFG_BACKUP_PASSPHRASE"
        fi

        if [[ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]] && [[ $decryption_success != "true" ]]; then
            attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "/" "$restore_place" "$restore_type" "CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE"
        fi

        if [[ $decryption_success != "true" ]]; then
            prompt_for_passphrase
            attempt_decryption "$passphrase" "/" "$restore_place" "$restore_type" "Custom Passphrase"
        fi
    fi

    # Full (Migrate only)
    if [[ "$restorefull" == [mM] ]]; then

        # Full Specific
        local restore_type="full"
        local restore_place="migrate"

        if [[ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]]; then
            attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "/" "$restore_place" "$restore_type" "CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE"
        fi

        if [[ $decryption_success != "true" ]]; then
            prompt_for_passphrase
            attempt_decryption "$passphrase" "/" "$restore_place" "$restore_type" "Custom Passphrase"
        fi
    fi

    # Local Restore or Remote Restore
    if [[ "$restoresingle" == [lLrR] ]]; then

        # Single Specific
        local restore_type="single"
        if [[ "$restoresingle" == [lL] ]]; then
            local restore_place="local"
        elif [[ "$restoresingle" == [rR] ]]; then
            local restore_place="remote"
        fi

        if [ -n "$CFG_BACKUP_PASSPHRASE" ]; then
            attempt_decryption "$CFG_BACKUP_PASSPHRASE" "$containers_dir" "$restore_place" "$restore_type" "CFG_BACKUP_PASSPHRASE"
        fi

        if [[ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]] && [[ $decryption_success != "true" ]]; then
            attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "$containers_dir" "$restore_place" "$restore_type" "CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE"
        fi

        if [[ $decryption_success != "true" ]]; then
            prompt_for_passphrase
            attempt_decryption "$passphrase" "$containers_dir" "$restore_place" "$restore_type" "Custom Passphrase"
        fi
    fi

    # Remote Migrate for Single Restore
    if [[ "$restoresingle" == [mM] ]]; then

        # Single Specific
        local restore_type="single"
        local restore_place="migrate"

        if [[ -n "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" ]]; then
            attempt_decryption "$CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE" "$containers_dir" "$restore_place" "$restore_type" "CFG_RESTORE_REMOTE_BACKUP_PASSPHRASE"
        fi

        if [[ $decryption_success != "true" ]]; then
            prompt_for_passphrase
            attempt_decryption "$passphrase" "/" "$restore_place" "$restore_type" "Custom Passphrase"
        fi
    fi
}