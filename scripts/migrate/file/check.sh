#!/bin/bash

migrateCheckForMigrateFiles() 
{
    # Check if there are files without the specified string
    local full_files_without_string=$(sudo ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")
    local single_files_without_string=$(sudo ls "$backup_single_dir" | sudo grep  -v "$CFG_INSTALL_NAME")
    # Combine the two lists of files
    local files_without_string="$full_files_without_string"$'\n'"$single_files_without_string"

    if [ -n "$files_without_string" ]; then
        migrateCheckForFullMigrateFiles;
        migrateCheckForSingleMigrateFiles;
        if [[ $migrateshowsingle == "true" ]] || [[ $migrateshowfull == "true" ]]; then
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
            if [[ $migrateshowfull == "true" ]]; then
                isOption "f: Full Backups"
            fi
            isOption "m: Move migration files to storage."
            echo ""
            # Question and Options
            isQuestion "Please select from the availables options above, or press 'c' to continue: "
            read -p "" migrationmainoptions
            case $migrationmainoptions in
                f|F)
                    migrateListFullMigrateFiles;
                    ;;
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

migrateCheckForFullMigrateFiles() 
{
    # Check if there are backup files found
    local full_backup_files=$(sudo ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

    if [ -n "$full_backup_files" ]; then
        migrateshowfull=true
    fi
}
