#!/bin/bash

restoreMigrate()
{
    if [[ "$restorefull" == [lLrRmM] ]]; then
        local app_name="full"
        local chosen_backup_file="$2"
        # Delete everything after the .zip extension in the file name
        local file_name=$(echo "$chosen_backup_file" | sed 's/\(.*\)\.zip/\1.zip/')
        backup_save_directory="$backup_full_dir"
        RESTORE_SAVE_DIRECTORY="$restore_full_dir"
        restoreStart "$app_name" "$file_name";
    elif [[ "$restoresingle" == [lLrRmM] ]]; then
        local app_name="$1"
        local chosen_backup_file="$2"
        # Delete everything after the .zip extension in the file name
        local file_name=$(echo "$chosen_backup_file" | sed 's/\(.*\)\.zip/\1.zip/')
        backup_save_directory="$backup_single_dir"
        RESTORE_SAVE_DIRECTORY="$restore_single_dir"
        restoreStart "$app_name" "$file_name";
    fi
}

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
            restoreSingleBackupList;
        elif [[ "$CFG_REQUIREMENT_MIGRATE" == "true" ]]; then
            backup_save_directory="$backup_single_dir"
            RESTORE_SAVE_DIRECTORY="$restore_single_dir"
            restoreSingleBackupList;
        fi
    fi
}