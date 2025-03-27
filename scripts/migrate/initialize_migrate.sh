#!/bin/bash

restoreMigrate()
{
    if [[ "$restoresingle" == [lLrRmM] ]]; then
        local app_name="$1"
        local chosen_backup_file="$2"
        # Delete everything after the .zip extension in the file name
        local file_name=$(echo "$chosen_backup_file" | sed 's/\(.*\)\.zip/\1.zip/')
        backup_save_directory="$backup_single_dir"
        RESTORE_SAVE_DIRECTORY="$restore_single_dir"
        restoreStart "$app_name" "$file_name";
    fi
}