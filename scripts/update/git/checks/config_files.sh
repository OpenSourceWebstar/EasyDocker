#!/bin/bash

gitCheckEasyDockerConfigFilesExist()
{
    local file_found_count=0

    for file in "${config_files_all[@]}"; do
        local file_path="$install_configs_dir$file"
        if [ -f "$file_path" ]; then
            if [ ! -f "$configs_dir$file" ]; then
                copyFile "silent" "$file_path" "$configs_dir$file" "$sudo_user_name"
            fi
            ((file_found_count++))
        else
            isNotice "Config File $file does not exist in $configs_dir."
        fi
    done
    
    if [ "$file_found_count" -eq "${#config_files_all[@]}" ]; then
        isSuccessful "All config files are successfully set up in the configs folder."
    else
        isFatalErrorExit "Not all config files were found in $configs_dir."
    fi
}

