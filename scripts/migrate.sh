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

migrateEnableConfig()
{
    while true; do
        isQuestion "Do you want to enable migration in the config file? (y/n): "
        read -rp "" enableconfigmigrate
        if [[ "$enableconfigmigrate" =~ ^[yYnN]$ ]]; then
            break
        fi
        isNotice "Please provide a valid input (y/n)."
    done
    if [[ $enableconfigmigrate == [yY] ]]; then
        local result=$(sudo sed -i "s/CFG_REQUIREMENT_MIGRATE="false"/CFG_REQUIREMENT_MIGRATE="true"/" "$configs_dir/$config_file_requirements")
        checkSuccess "Enabling CFG_REQUIREMENT_MIGRATE in $config_file_requirements"
    fi
    if [[ $enableconfigmigrate == [nN] ]]; then
        isNotice "Unable to enable migration."
        return 1
    fi

}

migrateGetAppName() 
{
    local selected_file=$(sudo echo "$1" | cut -d':' -f2- | sed 's/^ *//g')
    local selected_app_name=$(sudo echo "$selected_file" | sed 's/-backup.*//' | sed 's/.*-//')
    #echo "$selected_app_name"
}

migrateCheckForFullMigrateFiles() 
{
    # Check if there are backup files found
    local full_backup_files=$(sudo ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

    if [ -n "$full_backup_files" ]; then
        migrateshowfull=true
    fi
}

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

migrateCheckForSingleMigrateFiles() 
{
    # Check if there are backup files found
    local single_backup_files=$(sudo ls "$backup_single_dir" | grep -v "$CFG_INSTALL_NAME")

    if [ -n "$single_backup_files" ]; then
        migrateshowsingle=true
    fi
}

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

migrateRestoreFileMoveToMigrate()
{
  local app_name="$1"
  local chosen_backup_file="$2"

  while true; do
      echo ""
      isNotice "You have installed $app_name using the $chosen_backup_file"
      isNotice "You can now move the backup file to the migration folder for storage."
      isNotice "*TIP* You can also move the backup file back for future restorations using the migrate menu."
      echo ""
      isQuestion "Would you store $chosen_backup_file in the Migrate Folder? (y/n): "
      read -rp "" confirmmovetomigrate
      if [[ -n "$confirmmovetomigrate" ]]; then
          break
      fi
      isNotice "Please provide a valid input."
  done
  if [[ "$confirmmovetomigrate" == [yY] ]]; then
        if [[ $app_name == "" ]]; then
            isError "No app_name provided, unable to start restore."
            return 1
        elif [[ $app_name == "full" ]]; then
            local result=$(sudo mv $backup_full_dir/$chosen_backup_file $migrate_full_dir/$chosen_backup_file)
            checkSuccess "Moving $chosen_backup_file to $migrate_full_dir"
        else
            local result=$(sudo mv $backup_single_dir/$chosen_backup_file $migrate_single_dir/$chosen_backup_file)
            checkSuccess "Moving $chosen_backup_file to $migrate_single_dir"
        fi
  fi
  if [[ "$confirmmovetomigrate" == [nN] ]]; then
    while true; do
        echo ""
        isQuestion "Would you like to delete the $chosen_backup_file? (y/n): "
        read -rp "" confirmremovetomigrate
        if [[ -n "$confirmremovetomigrate" ]]; then
            break
        fi
        isNotice "Please provide a valid input."
    done
    if [[ "$confirmremovetomigrate" == [yY] ]]; then
        if [[ $app_name == "" ]]; then
            isError "No app_name provided, unable to start restore."
            return 1
        elif [[ $app_name == "full" ]]; then
            local result=$(sudo mv $backup_full_dir/$chosen_backup_file)
            checkSuccess "Deleting $chosen_backup_file in $backup_full_dir"
        else
            local result=$(sudo rm $backup_single_dir/$chosen_backup_file)
            checkSuccess "Deleting $chosen_backup_file in $backup_single_dir"
        fi
    fi
  fi
}

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
            local dst_path="$backup_single_dir/${file_to_move##*/}"
            echo ""
            local result=$(sudo mv "$src_path" "$dst_path")
            checkSuccess "Moving $(basename "$file_to_move") to $backup_single_dir"

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
                local dst_dir="$backup_single_dir"
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
                    checkSuccess "Moving $(basename "$file_to_move") to $backup_single_dir"
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

migrateGenerateTXTAll()
{
    echo ""
    echo "############################################"
    echo "######       Migration Install        ######"
    echo "############################################"
    echo ""

    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Loop through subdirectories
    for folder in "$containers_dir"/*; do
        # Extract the folder name from the full path
        local app_name=$(basename "$folder")
        if [ -d "$containers_dir/$app_name" ]; then

            # Check if a migrate.txt file exists in the current directory
            if [ ! -f "$migrate_file_path" ]; then
                migrateBuildTXT $app_name;
            fi
        fi
    done
    
    isSuccessful "Scanning and creating migrate.txt files completed."
}

migrateBuildTXT()
{
    local app_name=$1
    local migrate_file="migrate.txt"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Check if the migrate.txt file exists
    if [ ! -f "$migrate_file_path" ]; then
        # Create a migrate.txt file with IP and InstallName
        createTouch "$migrate_file_path" $CFG_DOCKER_INSTALL_USER

        # Add MIGRATE_IP options to $migrate_file for $app_name
        echo "MIGRATE_IP=$public_ip_v4" | sudo tee -a "$migrate_file_path" >/dev/null
        # Add MIGRATE_INSTALL_NAME options to $migrate_file for $app_name
        echo "MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME" | sudo tee -a "$migrate_file_path" >/dev/null

        isSuccessful "Created $migrate_file for $app_name"
    fi
}

migrateScanFoldersForUpdates()
{
    # Loop through all directories in the install path
    for folder in "$containers_dir"/*; do
        # Extract the folder name from the full path
        local app_name=$(basename "$folder")
        if [ -d "$containers_dir/$app_name" ]; then
            migrateSanitizeTXT $app_name;
            migrateCheckAndUpdateIP $app_name;
            migrateCheckAndUpdateInstallName $app_name;
        fi
    done
    
    isSuccessful "Migration IP checking and updating completed."
}

migrateGenerateTXTSingle()
{
    local app_name=$1
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"
    # Check if the specified directory exists
    if [ -d "$containers_dir/$app_name" ]; then
        # Check if a migrate.txt file already exists in the specified directory
        if [ ! -f "$migrate_file_path" ]; then
            migrateBuildTXT $app_name;
        else
            isNotice "$migrate_file already exists for $app_name."
            while true; do
                isQuestion "Do you want to update $migrate_file to the local machine? (y/n): "
                read -rp "" replacemigration
                if [[ "$replacemigration" =~ ^[yYnN]$ ]]; then
                    break
                fi
                isNotice "Please provide a valid input (y/n)."
            done
            if [[ "$replacemigration" == [yY] ]]; then
                migrateBuildTXT $app_name;
            fi
        fi
    else
        isNotice "The specified directory $app_name does not exist."
    fi
    
    isSuccessful "Generating $migrate_file for $app_name completed."
}


migrateSanitizeTXT()
{
    local app_name="$1"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Remove trailing non-text, non-number, non-special characters for lines starting with CFG_
    #sudo sed -i '/^CFG_/ s/[^[:alnum:]_]/ /g' "$migrate_file_path"
    #sudo dos2unix "$migrate_file_path" > /dev/null 2>&1
    #sudo sed -i 's/\r$//' "$migrate_file_path"
}

migrateCheckAndUpdateIP() 
{
    local app_name="$1"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"

    # Check if the migrate.txt file exists
    if [ -f "$migrate_file_path" ]; then
        local migrate_ip=$(sudo grep -o 'MIGRATE_IP=.*' "$migrate_file_path" | cut -d '=' -f 2)
        
        if [ "$migrate_ip" != "$public_ip_v4" ]; then
            if ! sudo grep -q "MIGRATE_IP=" "$migrate_file_path"; then
                # Add MIGRATE_IP if it's missing
                local result=$(sudo sed -i "1s/^/MIGRATE_IP=$public_ip_v4\n/" "$migrate_file_path")
                checkSuccess "Adding missing MIGRATE_IP for $app_name : $migrate_file."
            else
                # Update MIGRATE_IP if it's already there
                local result=$(sudo sed -i "s/MIGRATE_IP=.*/MIGRATE_IP=$public_ip_v4/" "$migrate_file_path")
                checkSuccess "Updated MIGRATE_IP for $app_name : $migrate_file to $public_ip_v4."
            fi
            
            # Replace old IP with the new IP in .yml and .env files
            local result=$(sudo find "$containers_dir/$app_name" -type f \( -name "*.yml" -o -name "*.env" \) -exec sudo sed -i "s|$migrate_ip|$public_ip_v4|g" {} \;)
            checkSuccess "Replaced old IP with $public_ip_v4 in .yml and .env files in $app_name."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}


migrateCheckAndUpdateInstallName() 
{
    local app_name="$1"
    local migrate_file_path="$containers_dir/$app_name/$migrate_file"
    # Check if the migrate.txt file exists
    if [ -f "$migrate_file_path" ]; then

        local existing_migrate_install_name=$(sudo grep -o 'MIGRATE_INSTALL_NAME=.*' "$migrate_file_path" | cut -d '=' -f 2)

        if [ -z "$existing_migrate_install_name" ]; then
            # If MIGRATE_INSTALL_NAME is not found, add it to the end of the file
            local result=$(sudo echo "MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME" | sudo tee -a "$migrate_file_path" > /dev/null)
            checkSuccess "Added MIGRATE_INSTALL_NAME to $migrate_file."
        elif [ "$existing_migrate_install_name" != "$CFG_INSTALL_NAME" ]; then
            # If the existing MIGRATE_INSTALL_NAME is different, update it
            local result=$(sudo sed -i "s/MIGRATE_INSTALL_NAME=.*/MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME/" "$migrate_file_path")
            checkSuccess "Updated MIGRATE_INSTALL_NAME in $migrate_file to $CFG_INSTALL_NAME."
        #else
            #checkNotice "MIGRATE_INSTALL_NAME in $migrate_file is already set to $CFG_INSTALL_NAME."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}

migrateUpdateFiles()
{            
    local app_name="$1"

    if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        local result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$containers_dir$app_name")
        checkSuccess "Updating ownership on migrated folder $app_name to $CFG_DOCKER_INSTALL_USER"

        if [[ $compose_setup == "default" ]]; then
            local compose_file="docker-compose.yml";
        elif [[ $compose_setup == "app" ]]; then
            local compose_file="docker-compose.$app_name.yml";
        fi

        local result=$(sudo sed -i \
            -e "s|- $docker_root_socket|- $docker_rootless_socket|g" \
            "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi

    if [[ $CFG_DOCKER_INSTALL_TYPE == "root" ]]; then
        local result=$(sudo sed -i \
            -e "s|- $docker_rootless_socket|- $docker_root_socket|g" \
            "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi

    fixPermissionsBeforeStart $app_name;
}