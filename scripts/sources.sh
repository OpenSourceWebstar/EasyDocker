#!/bin/bash

sourceFiles()
{
    local files_to_source=(
        "init.sh"

        "configs/config_backup"
        "configs/config_general"
        "configs/config_requirements"

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

    for file_to_source in "${files_to_source[@]}"; do
        if [ ! -f "$file_to_source" ]; then
            missing_files+=("$file_to_source")
        fi
    done

    echo "${missing_files[@]}"
}

loadContainerFiles() {
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$(echo "$file" | sed 's|/docker/install//||')"
        fi
    done < <(sudo find "$containers_dir" -type d \( -name 'resources' \) -prune -o -type f \( -name '*.sh' \) -print0)
}


loadConfigFiles() {
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$(echo "$file" | sed 's|/docker/install//||')"
        fi
    done < <(sudo find "$containers_dir" -type d \( -name 'resources' \) -prune -o -type f -name '*.config' -print0)
}

sourceScript() 
{
    local missing_files=($(sourceFiles))

    if [ ${#missing_files[@]} -eq 0 ]; then
        loadContainerFiles
        loadConfigFiles
        checkUpdates
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
        echo "OPTION : 2. Continue...*NOT RECOMMENDED*"
        echo "OPTION : x. Exit"
        echo ""
        read -rp "Enter your choice (1 or 2) or 'x' to skip : " choice
        case "$choice" in
            1)
                runInitReinstall;
                exit 0  # Exit the entire script
            ;;
            2)
                # User chose to continue
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
    sudo bash -c 'cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run'
    exit 0  # Exit the entire script
}

sourceScript;