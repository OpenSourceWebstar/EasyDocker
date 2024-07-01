#!/bin/bash

# Function to view and edit Docker Compose files in a selected app's folder
viewComposeFiles() 
{
  local app_names=()
  local app_dir

  echo ""
  echo "#################################"
  echo "### Docker Compose YML Editor ###"
  echo "#################################"
  echo ""
  isNotice "*WARNING* Only use this if you know what you are doing!"
  echo ""

  # Find all subdirectories under $containers_dir
  for app_dir in "$containers_dir"/*/; do
    if [[ -d "$app_dir" ]]; then
      # Extract the app name (folder name)
      local app_name=$(basename "$app_dir")
      local app_names+=("$app_name")
    fi
  done

  # Check if any apps were found
  if [ ${#app_names[@]} -eq 0 ]; then
    isNotice "No apps found in $containers_dir."
    return
  fi

  # List numbered options for app names
  isNotice "Select an app to view and edit Docker Compose files:"
  echo ""
  for i in "${!app_names[@]}"; do
    isOption "$((i + 1)). ${app_names[i]}"
  done

  # Read user input for app selection
  echo ""
  isQuestion "Enter the number of the app (or 'x' to exit): "
  read -p "" selected_option

  case "$selected_option" in
    [1-9]*)
      # Check if the selected option is a valid number
      if ((selected_option >= 1 && selected_option <= ${#app_names[@]})); then
        local selected_app="${app_names[selected_option - 1]}"
        local selected_app_dir="$containers_dir/$selected_app"

        # List Docker Compose files in the selected app's folder
        echo ""
        isNotice "Docker Compose files in '$selected_app':"
        local selected_compose_files=($(listDockerComposeFiles "$selected_app_dir"))

        # Check if any Docker Compose files were found
        if [ ${#selected_compose_files[@]} -eq 0 ]; then
          isNotice "No Docker Compose files found in '$selected_app'."
        else
          local original_checksums=()  # To store original MD5 checksums
          local edited_checksums=()    # To store edited MD5 checksums

          # Calculate the original MD5 checksums for the selected Docker Compose files
          for file in "${selected_compose_files[@]}"; do
            original_checksums+=("$(md5sum "$file" | cut -d ' ' -f 1)")
          done

          while true; do
            # List numbered options for Docker Compose files
            echo ""
            isNotice "Select Docker Compose files to edit (space-separated numbers, or 'x' to exit):"
            echo ""
            for i in "${!selected_compose_files[@]}"; do
              local compose_file_name=$(basename "${selected_compose_files[i]}")
              isOption "$((i + 1)). $compose_file_name"
            done

            # Read user input for file selection
            echo ""
            isQuestion "Enter the numbers of the files to edit (or 'x' to exit): "
            read -p "" selected_files

            case "$selected_files" in
              [0-9]*)
                # Edit the selected Docker Compose files with $CFG_TEXT_EDITOR
                local IFS=' '   # Declare IFS as a local variable
                read -r -a selected_file_numbers <<< "$selected_files"  # Declare selected_file_numbers as an array
                for file_number in "${selected_file_numbers[@]}"; do
                  local index=$((file_number - 1))
                  if ((index >= 0 && index < ${#selected_compose_files[@]})); then
                    local selected_file="${selected_compose_files[index]}"
                    sudo $CFG_TEXT_EDITOR "$selected_file"
                  fi
                done

                # Calculate the edited MD5 checksums for the selected Docker Compose files
                edited_checksums=()  # Clear the edited checksums
                for file in "${selected_compose_files[@]}"; do
                  edited_checksums+=("$(md5sum "$file" | cut -d ' ' -f 1)")
                done

                # Check if any files have been modified
                for i in "${!selected_compose_files[@]}"; do
                  if [ "${original_checksums[i]}" != "${edited_checksums[i]}" ]; then
                    isNotice "File ${selected_compose_files[i]} has been modified."
                    dockerComposeUpdateAndStartApp "$selected_app" restart;
                    break  # Stop processing files if any have been modified
                  fi
                done
                ;;
              x)
                isNotice "Exiting..."
                return
                ;;
              *)
                isNotice "Invalid option. Please choose valid file numbers or 'x' to exit."
                ;;
            esac
          done
        fi
      else
        isNotice "Invalid app number. Please choose a valid option."
      fi
      ;;
    x)
      isNotice "Exiting..."
      return
      ;;
    *)
      isNotice "Invalid option. Please choose a valid option or 'x' to exit."
      ;;
  esac
}
