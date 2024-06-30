#!/bin/bash

checkConfigFilesMissingFiles()
{
    local file_found_count=0
    local missing_files_count=0

    for file in "${config_files_all[@]}"; do
        if [ ! -f "$configs_dir$file" ]; then
            sudo cp "$install_configs_dir$file" "$configs_dir$file"
            ((missing_files_count++))
        fi
        ((file_found_count++))
    done
    
    if [ "$file_found_count" -eq "${#config_files_all[@]}" ]; then
        if [ "$missing_files_count" -gt 0 ]; then
            echo "${GREEN}SUCCESS:${NC}$missing_files_count config files were missing and have been added to the configs folder."
        else
            echo "${GREEN}SUCCESS:${NC}All config files are successfully set up in the configs folder."
        fi
    else
        echo "${RED}ERROR:${NC} Not all config files were found in $install_configs_dir."
    fi
}
