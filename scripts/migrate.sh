#!/bin/bash

migrateStart()
{

    if [[ "$CFG_MIGRATE_TYPE" == "local" ]]; then

        echo ""

    fi


    if [[ "$CFG_MIGRATE_TYPE" == "external" ]]; then

        migrateFull=true

		while true; do
			read -rp "Do you want to make a new backup locally? (y/n): " MIGRATEBACKUPLOCAL
			if [[ -n "$MIGRATEBACKUPLOCAL" ]]; then
				break
			fi
			isNotice "Please provide a valid input."
		done

	    if [[ "$MIGRATEBACKUPLOCAL" == [yY] ]]; then
            backupStart $app_name;
        fi
        

        restoreGetFile;

	    if [[ "$MIGBU" == [nN] ]]; then
            echo "Using latest available backup file"
            
        fi

        migrateFindLatestBackup;
        migrateTransferFile;

        migrateFull=false
    fi
}


migrateTransferFile()
{
    echo "Transfering file to $CFG_MIGRATE_EXTERNAL_IP"

    if [[ "$migrateFull" == "true" ]]; then
        remote_directory="$restore_dir/full/"
    fi

    #if [[ "$migrateSingle" == "true" ]]; then
        #remote_directory="$restore_dir/single/"
    #fi

    scp "$latestBackupFile" "$CFG_MIGRATE_EXTERNAL_USER@$CFG_MIGRATE_EXTERNAL_IP:$remote_directory"
}