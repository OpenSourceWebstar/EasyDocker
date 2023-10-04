#!/bin/bash

sourceSources()
{
    source scripts/sources.sh
}

files_to_source=(
    "init.sh"

    "scripts/variables.sh"
    "scripts/checks.sh"
    "scripts/menu.sh"
    "scripts/functions.sh"
    "scripts/update.sh"
    "scripts/docker.sh"
    "scripts/configs.sh"
    "scripts/whitelist.sh"
    "scripts/logs.sh"
    "scripts/permissions.sh"
    "scripts/database.sh"
    "scripts/network.sh"
    "scripts/shutdown.sh"

    "scripts/backup.sh"
    "scripts/restore.sh"
    "scripts/migrate.sh"
    
    "scripts/install/install_os.sh"
    "scripts/install/install_docker.sh"
    "scripts/install/install_ufw.sh"
    "scripts/install/install_misc.sh"
    "scripts/install/install_user.sh"
    "scripts/install/install_ssh.sh"
    "scripts/install/uninstall.sh"
)

sourceFiles()
{
    echo ""
    echo "####################################################"
    echo "###       Loading EasyDocker Startup Files       ###"
    echo "####################################################"
    echo ""
    for file_to_source in "${files_to_source[@]}"; do
        if [ ! -f "$file_to_source" ]; then
            echo "NOTICE: Missing file: $file_to_source"
        else
            source "$file_to_source"
            #echo "Sourced file: $file_to_source"
        fi
    done
    loadFiles "easydocker_configs";
    loadFiles "app_configs";
    loadFiles "containers";
}

sourceScripts() 
{
    local flag="$1"
    sourceFiles;
    local missing_files=()

    for file_to_source in "${files_to_source[@]}"; do
        if [ ! -f "$file_to_source" ]; then
            missing_files+=("$file_to_source")
            #echo "file_to_source $file_to_source"
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        isSuccessful "All files found and loaded for startup."
        if [[ $flag == "start" ]]; then
            checkUpdates;
        fi
    else
        echo ""
        echo "####################################################"
        echo "###       Missing EasyDocker Install Files       ###"
        echo "####################################################"
        echo ""
        for missing_file in "${missing_files[@]}"; do
            echo "NOTICE : It seems that $missing_file is missing from your EasyDocker Installation."
        done
        echo ""
        echo "OPTION : 1. Reinstall EasyDocker"
        echo "OPTION : x. Exit"
        echo ""
        read -rp "Enter your choice (1 or 2) or 'x' to skip : " choice
        case "$choice" in
            1)
                runInitReinstall;
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

runInitReinstall() 
{
    echo ""
    echo "####################################################"
    echo "###           Reinstalling EasyDocker            ###"
    echo "####################################################"
    echo ""
    sudo bash -c 'rm -rf /docker/install/ && cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run'
    exit 0  # Exit the entire script
}

loadFiles() 
{
    local load_type="$1"
    local file_pattern

    if [ "$load_type" = "easydocker_configs" ]; then
        local file_pattern="config_*"
        local folder_dir="$configs_dir"
    elif [ "$load_type" = "app_configs" ]; then
        local file_pattern="*.config"
        local folder_dir="$containers_dir"
    elif [ "$load_type" = "containers" ]; then
        local file_pattern="*.sh"
        local folder_dir="$install_containers_dir"
    else
        echo "Invalid load type: $load_type"
        return
    fi

    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$(echo "$file" | sed 's|/docker/install//||')"
            #echo "$load_type FILE $(echo "$file" | sed 's|/docker/install//||')"
        fi
    done < <(sudo find "$folder_dir" -type d \( -name 'resources' \) -prune -o -type f -name "$file_pattern" -print0)
}

sourceScripts "start";