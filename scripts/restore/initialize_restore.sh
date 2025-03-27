#!/bin/bash

restoreInitialize()
{
    if [[ "$CFG_REQUIREMENT_MIGRATE" == "false" ]]; then
        migrateEnableConfig;
    fi

    backup_save_directory="$backup_single_dir"
    RESTORE_SAVE_DIRECTORY="$restore_single_dir"
    restoreBackupList;
}