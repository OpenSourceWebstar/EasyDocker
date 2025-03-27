#!/bin/bash

checkRemoteBackupEnabled()
{
    # Used for checking if all remote backups are disabled
    if [ "$CFG_BACKUP_REMOTE_1_ENABLED" = "false" ] && [ "$CFG_BACKUP_REMOTE_2_ENABLED" = "false" ]; then
        remote_backups_disabled=true
    else
        remote_backups_disabled=false
    fi
}
