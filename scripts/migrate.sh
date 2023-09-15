#!/bin/bash

migrateCheckForMigrateFiles() 
{
    # Check if there are files without the specified string
    full_files_without_string=$(sudo -u $easydockeruser ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")
    single_files_without_string=$(sudo -u $easydockeruser ls "$backup_single_dir" | sudo grep  -v "$CFG_INSTALL_NAME")
    # Combine the two lists of files
    files_without_string="$full_files_without_string"$'\n'"$single_files_without_string"

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
            echo ""
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
        result=$(sudo sed -i "s/CFG_REQUIREMENT_MIGRATE="false"/CFG_REQUIREMENT_MIGRATE="true"/" "$configs_dir/$config_file_requirements")
        checkSuccess "Enabling CFG_REQUIREMENT_MIGRATE in $config_file_requirements"
    fi
    if [[ $enableconfigmigrate == [nN] ]]; then
        isNotice "Unable to enable migration."
        return 1
    fi

}

migrateGetAppName() 
{
    selected_file=$(sudo -u $easydockeruser echo "$1" | cut -d':' -f2- | sed 's/^ *//g')
    selected_app_name=$(sudo -u $easydockeruser echo "$selected_file" | sed 's/-backup.*//' | sed 's/.*-//')
    #echo "$selected_app_name"
}

migrateCheckForFullMigrateFiles() 
{
    # Check if there are backup files found
    local full_backup_files=$(sudo -u $easydockeruser ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

    if [ -n "$full_backup_files" ]; then
        migrateshowfull=true
    fi
}

migrateListFullMigrateFiles()
{
    # Find files not containing $CFG_INSTALL_NAME
    local full_files_without_string=$(sudo -u $easydockeruser ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

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
        selected_app_name=$(migrateGetAppName "$full_backup_file")
        restorefull=m
        restoreMigrate "$selected_app_name" "$full_backup_file"
        migrateshowfull=false
    done
}

migrateCheckForSingleMigrateFiles() 
{
    # Check if there are backup files found
    local single_backup_files=$(sudo -u $easydockeruser ls "$backup_single_dir" | grep -v "$CFG_INSTALL_NAME")

    if [ -n "$single_backup_files" ]; then
        migrateshowsingle=true
    fi
}

migrateListSingleMigrateFiles() {
    # Find files not containing $CFG_INSTALL_NAME
    local single_files_without_string=$(sudo -u $easydockeruser ls "$backup_single_dir" | grep -v "$CFG_INSTALL_NAME")

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
        selected_app_name=$(migrateGetAppName "$single_backup_file")
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
            result=$(sudo -u $easydockeruser mv $backup_full_dir/$chosen_backup_file $migrate_full_dir/$chosen_backup_file)
            checkSuccess "Moving $chosen_backup_file to $migrate_full_dir"
        else
            result=$(sudo -u $easydockeruser mv $backup_single_dir/$chosen_backup_file $migrate_single_dir/$chosen_backup_file)
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
            result=$(sudo -u $easydockeruser mv $backup_full_dir/$chosen_backup_file)
            checkSuccess "Deleting $chosen_backup_file in $backup_full_dir"
        else
            result=$(sudo -u $easydockeruser rm $backup_single_dir/$chosen_backup_file)
            checkSuccess "Deleting $chosen_backup_file in $backup_single_dir"
        fi
    fi
  fi
}

migrateRestoreFilesMoveToMigrate()
{
    # Find files not containing $CFG_INSTALL_NAME
    local full_files_without_string=$(sudo -u $easydockeruser ls "$backup_full_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

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
        result=$(sudo mv $backup_full_dir/$full_backup_file "$migrate_full_dir")
        checkSuccess "Moving $full_backup_file to $migrate_full_dir"
    done

    local single_files_without_string=$(sudo -u $easydockeruser ls "$backup_single_dir" | sudo grep  -v "$CFG_INSTALL_NAME")

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
                selected_files+=("$single_backup_file")
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
        result=$(sudo mv $backup_single_dir/$single_backup_file "$migrate_single_dir")
        checkSuccess "Moving $single_backup_file to $migrate_single_dir"
    done
}

migrateRestoreFileMoveFromMigrate() {
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
            file_count=$(sudo find "$migrate_single_dir" -maxdepth 1 -type f -name "*.zip" | wc -l)
            if [ "$file_count" -eq 0 ]; then
                echo ""
                isNotice "No files found in $migrate_single_dir"
                continue
            fi
            files=( $(sudo find "$migrate_single_dir" -maxdepth 1 -type f -name "*.zip") )
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
            file_to_move="${files[file_choice-1]}"
            src_path="$file_to_move"
            dst_path="$backup_single_dir/${file_to_move##*/}"
            echo ""
            result=$(sudo -u $easydockeruser mv "$src_path" "$dst_path")
            checkSuccess "Moving $(basename "$file_to_move") to $backup_single_dir"

        elif [ "$choice" = "2" ]; then
            file_count=$(sudo find "$migrate_full_dir" -maxdepth 1 -type f -name "*.zip" | wc -l)
            if [ "$file_count" -eq 0 ]; then
                echo ""
                isNotice "No files found in $migrate_full_dir"
                continue
            fi
            files=( $(sudo find "$migrate_full_dir" -maxdepth 1 -type f -name "*.zip") )
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
            file_to_move="${files[file_choice-1]}"
            src_path="$file_to_move"
            dst_path="$backup_full_dir/${file_to_move##*/}"
            echo ""
            result=$(sudo -u $easydockeruser mv "$src_path" "$dst_path")
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
                src_dir="$migrate_single_dir"
                dst_dir="$backup_single_dir"
            elif [ "$backup_choice" = "2" ]; then
                src_dir="$migrate_full_dir"
                dst_dir="$backup_full_dir"
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
            file_count=$(find "$src_dir" -maxdepth 1 -type f -name "*.zip" | wc -l)
            if [ "$file_count" -eq 0 ]; then
                echo ""
                isNotice "No files found in $src_dir... returning to previous menu."
                continue
            fi
            files=( $(sudo find "$src_dir" -maxdepth 1 -type f -name "*.zip") )
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
                    src_path="$f"
                    dst_path="$dst_dir/${f##*/}"
                    result=$(sudo -u $easydockeruser mv "$src_path" "$dst_path")
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

    # Loop through subdirectories
    for folder in "$install_path"/*; do
        # Extract the folder name from the full path
        app_name=$(basename "$folder")
        if [ -d "$install_path/$app_name" ]; then

            # Check if a migrate.txt file exists in the current directory
            if [ ! -f "$install_path/$app_name/$migrate_file" ]; then
                migrateBuildTXT $app_name;
            fi
        fi
    done
    
    isSuccessful "Scanning and creating migrate.txt files completed."
}

migrateBuildTXT()
{
    local app_name=$1

    # Create a migrate.txt file with IP and InstallName
    createTouch "$install_path/$app_name/$migrate_file"

    # Add MIGRATE_IP options to $migrate_file for $app_name
    echo "MIGRATE_IP=$public_ip" | sudo tee -a "$install_path/$app_name/$migrate_file" >/dev/null
    # Add MIGRATE_INSTALL_NAME options to $migrate_file for $app_name
    echo "MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME" | sudo tee -a "$install_path/$app_name/$migrate_file" >/dev/null

    isSuccessful "Created $migrate_file for $app_name"
}

migrateScanFoldersForUpdates()
{
    # Loop through all directories in the install path
    for folder in "$install_path"/*; do
        # Extract the folder name from the full path
        local app_name=$(basename "$folder")
        if [ -d "$install_path/$app_name" ]; then
            migrateCheckAndUpdateIP $app_name;
            migrateCheckAndUpdateInstallName $app_name;
        fi
    done
    
    isSuccessful "Migration IP checking and updating completed."
}

migrateGenerateTXTSingle()
{
    local app_name=$1
    # Check if the specified directory exists
    if [ -d "$install_path/$app_name" ]; then
        # Check if a migrate.txt file already exists in the specified directory
        if [ ! -f "$install_path/$app_name/$migrate_file" ]; then
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

migrateCheckAndUpdateIP() 
{
    local app_name="$1"
    
    # Check if the migrate.txt file exists
    if [ -f "$install_path/$app_name/$migrate_file" ]; then
        local migrate_file="$install_path/$app_name/$migrate_file"
        local migrate_ip=$(sudo grep -o 'MIGRATE_IP=.*' "$migrate_file" | cut -d '=' -f 2)
        if [ "$migrate_ip" != "$public_ip" ]; then
            if ! sudo grep -q "MIGRATE_IP=" "$migrate_file"; then
                result=$(sudo sed -i "1s/^/MIGRATE_IP=$public_ip\n/" "$migrate_file")
                checkSuccess "Adding missing MIGRATE_IP for $app_name : $(basename "$migrate_file")."
            else
                result=$(sudo sed -i "s#MIGRATE_IP=.*#MIGRATE_IP=$public_ip#" "$migrate_file")
                checkSuccess "Updated MIGRATE_IP for $app_name : $(basename "$migrate_file") to $public_ip."
            fi
            result=$(sudo find "$install_path/$app_name" -type f \( -name "*.yml" -o -name "*.env" \) -exec sed -i "s/$migrate_ip/$public_ip/g" {} \;)
            checkSuccess "Replaced old IP with $public_ip in .yml and .env files in $app_name."
        fi
    else
        isError "$migrate_file not found in $app_name."
    fi
}

migrateCheckAndUpdateInstallName() {
    local app_name="$1"

    # Check if the migrate.txt file exists
    if [ -f "$install_path/$app_name/$migrate_file" ]; then
        local migrate_file="$install_path/$app_name/$migrate_file"
        local existing_migrate_install_name=$(sudo grep -o 'MIGRATE_INSTALL_NAME=.*' "$migrate_file" | cut -d '=' -f 2)

        if [ -z "$existing_migrate_install_name" ]; then
            # If MIGRATE_INSTALL_NAME is not found, add it to the end of the file
            result=$(sudo echo "MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME" | sudo tee -a "$migrate_file" > /dev/null)
            checkSuccess "Added MIGRATE_INSTALL_NAME to $(basename "$migrate_file")."
        elif [ "$existing_migrate_install_name" != "$CFG_INSTALL_NAME" ]; then
            # If the existing MIGRATE_INSTALL_NAME is different, update it
            result=$(sudo sed -i "s/MIGRATE_INSTALL_NAME=.*/MIGRATE_INSTALL_NAME=$CFG_INSTALL_NAME/" "$migrate_file")
            checkSuccess "Updated MIGRATE_INSTALL_NAME in $(basename "$migrate_file") to $CFG_INSTALL_NAME."
        #else
            #checkNotice "MIGRATE_INSTALL_NAME in $(basename "$migrate_file") is already set to $CFG_INSTALL_NAME."
        fi
    else
        isError "$(basename "$migrate_file") not found in $app_name."
    fi
}

# Function to apply variables from config files to migrate.txt
migrateScanConfigsToMigrate() 
{
  # Find all subdirectories under the installation path and use them as app names
  local app_names=()

  # Loop through the contents of the install_path directory
  for item in "$install_path"/*; do
    if [[ -d "$item" ]]; then
      # If it's a directory, add its basename to app_names
      app_names+=("$(basename "$item")")
    fi
  done

  for app_name in "${app_names[@]}"; do
    # Capitalize the app name
    app_name_upper="CFG_$(tr '[:lower:]' '[:upper:]' <<< "${app_name}")"
    #echo "Processing app_name: $app_name"

    # Define the migrate.txt file for the app
    local migrate_file="$install_path/$app_name/migrate.txt"
    #echo "Migrate file: $migrate_file"

    # Read the content of migrate.txt into an array
    declare -a migrate_lines
    if [[ -f "$migrate_file" ]]; then
      mapfile -t migrate_lines < "$migrate_file"
    fi

    # Create an associative array to track variable names in migrate.txt
    declare -A existing_variables

    # Populate the associative array with variable names from migrate.txt
    for migrate_line in "${migrate_lines[@]}"; do
      # Extract the variable name (content before '=')
      variable_name="${migrate_line%%=*}"
      existing_variables["$variable_name"]=1
    done

    # Loop through all config files matching the pattern config_apps_*
    for config_file in "$configs_dir"/config_apps_*; do
      if [[ -f "$config_file" ]]; then
        #echo "Processing config file: $config_file"
        # Read the config file line by line
        while IFS= read -r line; do
          # Check if the line matches the pattern CFG_APP_NAME* (contains CFG_APP_NAME)
          if [[ "$line" =~ $app_name_upper ]]; then
            #echo "Found line in $config_file: $line"

            # Extract the variable name (content before '=')
            variable_name="${line%%=*}"

            # Check if the variable name (content before '=') is not in migrate.txt
            if [[ -z "${existing_variables[$variable_name]}" ]]; then
              #echo "Adding line to migrate.txt ($migrate_file): $line"
              # Append the line to migrate.txt
              echo "$line" | sudo tee -a "$migrate_file" >/dev/null
              # Update the associative array
              existing_variables["$variable_name"]=1
            fi
          fi
        done < "$config_file"
      fi
    done
  done

  isSuccessful "App config values have been updated in migrate.txt files"

  # Clear variables used in the function
  unset app_names migrate_file migrate_lines existing_variables
}

# Function to apply variables from migrate.txt to config files
migrateScanMigrateToConfigs() 
{
  isNotice "Scanning migrate.txt files... this may take a moment..."
  
  # Variables to ignore
  local ignore_vars=("MIGRATE_IP" "MIGRATE_INSTALL_NAME")

  # Find all subdirectories under the installation path and use them as app names
  local app_names=()

  # Loop through the contents of the install_path directory
  for item in "$install_path"/*; do
    if [[ -d "$item" ]]; then
      # If it's a directory, add its basename to app_names
      app_names+=("$(basename "$item")")
    fi
  done

  # Initialize an array to store variables found in any config file
  local found_vars=()

  for app_name in "${app_names[@]}"; do
    # Capitalize the app name
    app_name_upper="CFG_$(tr '[:lower:]' '[:upper:]' <<< "${app_name}")"
    #echo "Processing app_name: $app_name" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1

    # Define the migrate.txt file for the app
    local migrate_file="$install_path/$app_name/migrate.txt"
    #echo "Migrate file: $migrate_file" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1

    # Check if migrate.txt exists and read variables
    if [[ -f "$migrate_file" ]]; then
      while IFS='=' read -r var_name var_value; do
        # Check if the variable should be ignored
        if [[ " ${ignore_vars[*]} " == *"$var_name"* ]]; then
          #echo "Ignoring variable: $var_name"  | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
          continue
        fi

        # Initialize a flag to indicate whether the app_name_upper section was found
        section_found=0
        last_cfg_line=""

        # Initialize a flag to indicate if the variable was found in any config file
        var_found=0

        # Loop through all config files matching the pattern config_apps_*
        for config_file in "$configs_dir"/config_apps_*; do
          if [[ -f "$config_file" ]]; then
            # Search for the app_name_upper in the config file
            if sudo grep  -q "$app_name_upper" "$config_file"; then
              section_found=1
              last_cfg_line=""
            fi

            # If the app_name_upper section was found and the line is not empty, store it
            if [[ $section_found -eq 1 ]] && [[ -n "$last_cfg_line" ]]; then
              last_cfg_line="$last_cfg_line"$'\n'"$var_name=$var_value"
            fi

            # If the variable is found in this config file, set var_found to 1
            if sudo grep  -q "^$var_name=" "$config_file"; then
              var_found=1
              found_vars+=("$var_name")
              # Extract the existing value from the config
              existing_value=$(sudo grep  -oP "(?<=^$var_name=).*" "$config_file")
              # Check if the existing value is different from the value in migrate.txt
              if [[ "$existing_value" != "$var_value" ]]; then
                # Update the value in the config
                sudo sed -i "s/^$var_name=$existing_value/$var_name=$var_value/" "$config_file"
                #echo "Updated variable $var_name in $config_file to $var_value" | sudo -u $easydockeruser tee -a "$logs_dir/$docker_log_file" 2>&1
              fi
            fi
          fi
        done

        # If the app_name_upper section was found and the variable is not found in any config file, add it
        if [[ $section_found -eq 1 ]] && [[ -n "$last_cfg_line" ]] && [[ $var_found -eq 0 ]]; then
          # Add the variable to the last_cfg_line
          last_cfg_line="$last_cfg_line"$'\n'"$var_name=$var_value"
        fi
      done < "$migrate_file"
    fi
  done

  # Add variables from migrate.txt to system config only if they do not exist in any config file
  for var_name in "${found_vars[@]}"; do
    var_exists=0
    for config_file in "$configs_dir"/config_apps_*; do
      if [[ -f "$config_file" ]] && sudo grep  -q "^$var_name=" "$config_file"; then
        var_exists=1
        break
      fi
    done
    if [[ $var_exists -eq 0 ]]; then
        echo "$var_name=${!var_name}" | sudo tee -a "$configs_dir/config_apps_system" >/dev/null
        #echo "Stored variable $var_name=${!var_name} in config_apps_system" | sudo tee -a "$logs_dir/$docker_log_file" 2>&1 >/dev/null
    fi
  done

  isSuccessful "Variables from migrate.txt have been applied to config files"

  # Clear variables used in the function
  unset ignore_vars app_names found_vars section_found last_cfg_line var_found var_exists
}

migrateUpdateFiles()
{            
    local app_name="$1"
    if [[ $CFG_REQUIREMENT_DOCKER_ROOTLESS == "true" ]]; then
        result=$(sudo chown -R $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER "$install_path$app_name")
        checkSuccess "Updating ownership on migrated folder $app_name to $CFG_DOCKER_INSTALL_USER"
        local compose_file="$install_path$app_name/docker-compose.yml"
        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")

        result=$(sudo sed -i \
            -e "s|- /var/run/docker.sock|- /run/user/${docker_install_user_id}/docker.sock|g" \
            "$compose_file")
        checkSuccess "Updating Compose file for $app_name"
    fi

    fixPermissionsBeforeStart $app_name
}