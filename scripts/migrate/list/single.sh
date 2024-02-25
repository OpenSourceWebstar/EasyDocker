#!/bin/bash

migrateListSingleMigrateFiles() 
{
    # Find files not containing $CFG_INSTALL_NAME
    local single_files_without_string=$(sudo ls "$backup_single_dir" | grep -v "$CFG_INSTALL_NAME")

    # Output list of filenames found
    if [ -n "$single_files_without_string" ]; then
        echo ""
        isNotice "The following files were found:"
        echo ""
        while IFS= read -r file; do
            isOption "$file"
        done <<< "$single_files_without_string"
        echo ""
    else
        isNotice "No files were found."
        return
    fi

    # Prompt user for each file
    local selected_files=()
    for single_backup_file in $single_files_without_string; do
        isQuestion "Do you want to restore $single_backup_file? (y/n): "
        read -p "" singlemigrateoption
        case $singlemigrateoption in
            y|Y)
                selected_files+=("$single_backup_file")
                ;;
            n|N)
                #echo "Skipping $single_backup_file."
                ;;
            *)
                isNotice "Invalid option. Skipping $single_backup_file."
                ;;
        esac
    done

    # Restore selected files
    for single_backup_file in "${selected_files[@]}"; do
        local selected_app_name=$(migrateGetAppName "$single_backup_file")
        restoresingle=m
        restoreMigrate "$selected_app_name" "$single_backup_file"
        migrateshowsingle=false
    done
}
