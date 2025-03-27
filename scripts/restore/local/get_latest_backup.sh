#!/bin/bash

# Function to get the latest backup file for a given app
getLatesLocaltBackupFile() 
{
    local app_name="$1"
    ls -t "$backup_save_directory"/*-"$app_name"-backup-* 2>/dev/null | head -n 1
}