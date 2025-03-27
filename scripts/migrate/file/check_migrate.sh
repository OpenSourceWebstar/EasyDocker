#!/bin/bash

migrateCheckForMigrateFiles() 
{
    # Check if there are files without the specified string
    local single_files_without_string=$(sudo ls "$backup_single_dir" | sudo grep -v "$CFG_INSTALL_NAME")

    if [ -n "$single_files_without_string" ]; then
        migrateCheckForSingleMigrateFiles;
        if [[ $migrateshowsingle == "true" ]]; then
            echo ""
            echo "#####################################"
            echo "###        Migration Backups      ###"
            echo "#####################################"
            echo ""
            isNotice "Potential migration files found in the backups folder."
            isNotice "Please select the file you would like to restore."
            echo ""
            if [[ $migrateshowsingle == "true" ]]; then
                isOption "s: Single App Backups"
            fi
            isOption "m: Move migration files to storage."
            echo ""
            # Question and Options
            isQuestion "Please select from the available options above, or press 'c' to continue: "
            read -p "" migrationmainoptions
            case $migrationmainoptions in
                s|S)
                    migrateListSingleMigrateFiles;
                    ;;
                m|M)
                    migrateRestoreFilesMoveToMigrate;
                    ;;
                c|C)
                    return
                    ;;
            esac
        else
            isSuccessful "No backup files found for migration."
        fi
    fi
}

migrateCheckForSingleMigrateFiles() 
{
    # Check if there are backup files found
    local single_backup_files=$(sudo ls "$backup_single_dir" | grep -v "$CFG_INSTALL_NAME")

    if [ -n "$single_backup_files" ]; then
        migrateshowsingle=true
    fi
}
