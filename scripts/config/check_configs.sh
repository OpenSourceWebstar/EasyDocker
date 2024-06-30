#!/bin/bash

checkConfigFilesMissingFiles()
{
    local file_found_count=0
    local missing_files_count=0

    for file in "${config_files_all[@]}"; do
        local file_path="$install_configs_dir$file"
        if [ -f "$file_path" ]; then
            if [ ! -f "$configs_dir$file" ]; then
                copyFile "silent" "$file_path" "$configs_dir$file" "$sudo_user_name"
                ((missing_files_count++))
            fi
            ((file_found_count++))
        else
            isNotice "Config File $file does not exist in $install_configs_dir."
        fi
    done
    
    if [ "$file_found_count" -eq "${#config_files_all[@]}" ]; then
        if [ "$missing_files_count" -gt 0 ]; then
            isSuccessful "$missing_files_count config files were missing and have been added to the configs folder."
        else
            isSuccessful "All config files are successfully set up in the configs folder."
        fi
    else
        isFatalErrorExit "Not all config files were found in $install_configs_dir."
    fi
}
