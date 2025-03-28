#!/bin/bash

restoreInitialize()
{
    if [[ "$CFG_REQUIREMENT_MIGRATE" == "false" ]]; then
        migrateEnableConfig;
    fi

    RESTORE_SAVE_DIRECTORY="$restore_single_dir"
    restoreBackupList;
}