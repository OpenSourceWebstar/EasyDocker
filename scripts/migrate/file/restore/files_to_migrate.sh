#!/bin/bash

migrateRestoreFilesMoveToMigrate()
{
    # Find files not containing $CFG_INSTALL_NAME
    local full_files_without_string=$(sudo ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

    # Output list of filenames found
    if [ -n "$full_files_without_string" ]; then
        echo ""
        isNotice "The following Full backup files were found:"
        echo ""
        while IFS= read -r file; do
            isOption "$file"
        done <<< "$full_files_without_string"
        echo ""
    else
        isNotice "No Full backup files were found."
        return
    fi


    # Prompt user for each file
    local selected_files=()
    for full_backup_file in $full_files_without_string; do
        isQuestion "Do you want to move $full_backup_file to the migrate folder for storage? (y/n): "
        read -p "" fullmovemigrateoption
        case $fullmovemigrateoption in
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
        echo ""
        local result=$(sudo mv $backup_full_dir/$full_backup_file "$migrate_full_dir")
        checkSuccess "Moving $full_backup_file to $migrate_full_dir"
    done

    local single_files_without_string=$(sudo ls "$backup_single_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

    # Output list of filenames found
    if [ -n "$single_files_without_string" ]; then
        echo ""
        isNotice "The following single backup files were found:"
        echo ""
        while IFS= read -r file; do
            isOption "$file"
        done <<< "$single_files_without_string"
        echo ""
    else
        echo ""
        isNotice "No single backup files were found."
        return
    fi


    # Prompt user for each file
    local selected_files=()
    for single_backup_file in $single_files_without_string; do
        echo ""
        isQuestion "Do you want to move $single_backup_file to the migrate folder for storage? (y/n): "
        read -p "" singlemovemigrateoption
        case $singlemovemigrateoption in
            y|Y)
                local selected_files+=("$single_backup_file")
                ;;
            n|N)
                ;;
            *)
                isNotice "Invalid option. Skipping $single_backup_file."
                ;;
        esac
    done


    # Restore selected files
    for single_backup_file in "${selected_files[@]}"; do
        echo ""
        local result=$(sudo mv $backup_single_dir/$single_backup_file "$migrate_single_dir")
        checkSuccess "Moving $single_backup_file to $migrate_single_dir"
    done
}