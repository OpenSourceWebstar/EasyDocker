#!/bin/bash

sourceCheckFiles() 
{
    local flag="$1"
    sourceInitilize $flag;

    # Checking for mising files
    local missing_files=()
    for file_to_source in "${files_to_source[@]}"; do
        if [ ! -f "${install_scripts_dir}${file_to_source}" ]; then
            missing_files+=("${install_scripts_dir}${file_to_source}")
            #echo "file_to_source ${install_scripts_dir}${file_to_source}"
        fi
    done

    # If there was no missing files
    if [ ${#missing_files[@]} -eq 0 ]; then
        # This is where the run command starts
        if [[ $flag == "run" ]]; then
            isSuccessful "All files found and loaded for startup."
            detectOS;
            checkUpdates;
        # This is where the CLI command starts
        elif [[ $flag == "cli" ]]; then
            detectOS;
            cliInitialize;
        fi
    
    # Reinstall EasyDocker if there is missing files
    else
        echo ""
        echo "####################################################"
        echo "###       Missing EasyDocker Install Files       ###"
        echo "####################################################"
        echo ""
        for missing_file in "${missing_files[@]}"; do
            echo "NOTICE : It seems that ${missing_file} is missing from your EasyDocker Installation."
        done
        echo ""
        echo "OPTION : 1. Reinstall EasyDocker"
        echo "OPTION : x. Exit"
        echo ""
        read -rp "Enter your choice (1 or 2) or 'x' to skip : " choice
        case "$choice" in
            1)
                runReinstall;
                exit 0  # Exit the entire script
            ;;
            [xX])
                # User chose to exit
                exit 1
            ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 'x'."
            ;;
        esac
    fi

}
