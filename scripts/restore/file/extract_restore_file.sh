#!/bin/bash

restoreExtractFile()
{
    cd $RESTORE_SAVE_DIRECTORY

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
            prompt_passphrase
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
            prompt_passphrase
            attempt_decryption "$passphrase" "/" "$restore_place" "$restore_type" "Custom Passphrase"
        fi
    fi
}