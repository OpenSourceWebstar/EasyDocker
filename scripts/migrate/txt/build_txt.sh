#!/bin/bash

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
