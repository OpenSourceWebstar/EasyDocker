#!/bin/bash

restoreInitialize()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        if [[ "$CFG_REQUIREMENT_MIGRATE" == "false" ]]; then
            migrateEnableConfig;
            backup_save_directory="$backup_full_dir"
            RESTORE_SAVE_DIRECTORY="$restore_full_dir"
            restoreFullBackupList;
        elif [[ "$CFG_REQUIREMENT_MIGRATE" == "true" ]]; then
            backup_save_directory="$backup_full_dir"
            RESTORE_SAVE_DIRECTORY="$restore_full_dir"
            restoreFullBackupList;
        fi
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        if [[ "$CFG_REQUIREMENT_MIGRATE" == "false" ]]; then
            migrateEnableConfig;
            backup_save_directory="$backup_single_dir"
            RESTORE_SAVE_DIRECTORY="$restore_single_dir"
            restoreSingleBackupList $backup_save_directory;
        elif [[ "$CFG_REQUIREMENT_MIGRATE" == "true" ]]; then
            backup_save_directory="$backup_single_dir"
            RESTORE_SAVE_DIRECTORY="$restore_single_dir"
            restoreSingleBackupList $backup_save_directory;
        fi
    fi
}