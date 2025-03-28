#!/bin/bash

migrateRestoreFileMoveFromMigrate() 
{
    while true; do
        echo ""
        isNotice "Please select an option:"
        echo ""
        isOption "1. Single backups"
        isOption "2. Full backups"
        isOption "3. Bulk move"
        echo ""
        isQuestion "Enter your choice (1/2/3) or press (x) to exit: "
        read -p "" choice

        if [ "$choice" = "1" ]; then
            local file_count=$(sudo find "$migrate_single_dir" -maxdepth 1 -type f -name "*.zip" | wc -l)
            if [ "$file_count" -eq 0 ]; then
                echo ""
                isNotice "No files found in $migrate_single_dir"
                continue
            fi
            local files=( $(sudo find "$migrate_single_dir" -maxdepth 1 -type f -name "*.zip") )
            echo ""
            isNotice "Please select a file to move:"
            echo ""
            for i in "${!files[@]}"; do
                isOption "$((i+1)). ${files[i]##*/}"
            done
            echo ""
            isQuestion "Enter the file number or press (x) to exit : "
            read -p "" file_choice
            if [ -z "$file_choice" ]; then
                continue
            fi
            if [[ $file_choice == "x" ]]; then
                return 1
            fi
            if ! [[ "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt ${#files[@]} ]; then
                isNotice "Invalid file number"
                continue
            fi
            local file_to_move="${files[file_choice-1]}"
            local src_path="$file_to_move"
            local dst_path="$backup_dir/${file_to_move##*/}"
            echo ""
            local result=$(sudo mv "$src_path" "$dst_path")
            checkSuccess "Moving $(basename "$file_to_move") to $backup_dir"

        elif [ "$choice" = "2" ]; then
            local file_count=$(sudo find "$migrate_full_dir" -maxdepth 1 -type f -name "*.zip" | wc -l)
            if [ "$file_count" -eq 0 ]; then
                echo ""
                isNotice "No files found in $migrate_full_dir"
                continue
            fi
            local files=( $(sudo find "$migrate_full_dir" -maxdepth 1 -type f -name "*.zip") )
            echo ""
            isNotice "Select a file to move:"
            for i in "${!files[@]}"; do
                isOption "$((i+1)). ${files[i]##*/}"
            done

            isQuestion "Enter the file number: "
            read -p "" file_choice
            if [ -z "$file_choice" ]; then
                continue
            fi
            if ! [[ "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt ${#files[@]} ]; then
                echo "Invalid file number"
                continue
            fi
            local file_to_move="${files[file_choice-1]}"
            local src_path="$file_to_move"
            local dst_path="$backup_full_dir/${file_to_move##*/}"
            echo ""
            local result=$(sudo mv "$src_path" "$dst_path")
            checkSuccess "Moving $(basename "$file_to_move") to $backup_full_dir"

        elif [ "$choice" = "3" ]; then
            echo ""
            isNotice "Please select a backup type:"
            echo ""
            isOption "1. Single backups"
            isOption "2. Full backups"
            echo ""
            isQuestion "Enter your choice (1/2) or (b) to go Back or (x) to exit : "
            read -p "" backup_choice
            if [ "$backup_choice" = "1" ]; then
                local src_dir="$migrate_single_dir"
                local dst_dir="$backup_dir"
            elif [ "$backup_choice" = "2" ]; then
                local src_dir="$migrate_full_dir"
                local dst_dir="$backup_full_dir"
            elif [ "$backup_choice" = "b" ]; then
                echo ""
                isNotice "Going back to the main menu..."
                migrateRestoreFileMoveFromMigrate;
            elif [ "$backup_choice" = "x" ]; then
                return 1
            else
                echo ""
                isNotice "Invalid choice"
                continue
            fi
            local file_count=$(sudo find "$src_dir" -maxdepth 1 -type f -name "*.zip" | wc -l)
            if [ "$file_count" -eq 0 ]; then
                echo ""
                isNotice "No files found in $src_dir... returning to previous menu."
                continue
            fi
            local files=( $(sudo find "$src_dir" -maxdepth 1 -type f -name "*.zip") )
            echo ""
            isNotice "Files to be moved :"
            echo ""
            for f in "${files[@]}"; do
                isNotice "$(basename "$f")"
            done
            while true; do
                echo ""
                isQuestion "Do you want to move all the files above to the Backup folder? (y/n): "
                read -rp "" migrateconfirmmove
                if [[ -n "$migrateconfirmmove" ]]; then
                    break
                fi
                isNotice "Please provide a valid input."
            done
            if [[ "$migrateconfirmmove" == [yY] ]]; then
                for f in "${files[@]}"; do
                    local src_path="$f"
                    local dst_path="$dst_dir/${f##*/}"
                    local result=$(sudo mv "$src_path" "$dst_path")
                    checkSuccess "Moving $(basename "$file_to_move") to $backup_dir"
                done
                echo ""
                isSuccessful "Files moved successfully"
            fi
            migrateconfirmmove=n
        elif [ "$choice" = "x" ]; then
            return 1
        else
            echo ""
            isNotice "Invalid choice"
            continue
        fi
    done
}

