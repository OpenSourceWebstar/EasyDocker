#!/bin/bash

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
            local result=$(sudo mv $backup_dir/$chosen_backup_file $migrate_single_dir/$chosen_backup_file)
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
            local result=$(sudo rm $backup_dir/$chosen_backup_file)
            checkSuccess "Deleting $chosen_backup_file in $backup_dir"
        fi
    fi
  fi
}
