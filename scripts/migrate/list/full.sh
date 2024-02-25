#!/bin/bash

migrateListFullMigrateFiles()
{
    # Find files not containing $CFG_INSTALL_NAME
    local full_files_without_string=$(sudo ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

    # Output list of filenames found
    if [ -n "$full_files_without_string" ]; then
        echo ""
        isNotice "The following files were found:"
        echo ""
        while IFS= read -r file; do
            isOption "$file"
        done <<< "$full_files_without_string"
        echo ""
    else
        isNotice "No files were found."
        return
    fi

    # Prompt user for each file
    local selected_files=()
    for full_backup_file in $full_files_without_string; do
        echo ""
        isQuestion "Do you want to restore $full_backup_file? (y/n): "
        read -p "" fullmigrateoption
        case $fullmigrateoption in
            y|Y)
                selected_files+=("$full_backup_file")
                ;;
            n|N)
                ;;
            *)
                isNotice "Invalid option. Skipping $full_backup_file."
                ;;
        esac
    done

    # Restore selected files
    for full_backup_file in "${selected_files[@]}"; do
        local selected_app_name=$(migrateGetAppName "$full_backup_file")
        restorefull=m
        restoreMigrate "$selected_app_name" "$full_backup_file"
        migrateshowfull=false
    done
}
