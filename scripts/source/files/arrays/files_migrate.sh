#!/bin/bash

migrate_scripts=(
    "migrate/file/restore/files_to_migrate.sh"
    "migrate/file/restore/file_from_migrate.sh"
    "migrate/file/restore/file_to_migrate.sh"
    "migrate/file/check_migrate.sh"
    "migrate/file/update_migrate.sh"

    "migrate/list/single_migrate_files.sh"

    "migrate/txt/build_txt.sh"
    "migrate/txt/generate_all_txt.sh"
    "migrate/txt/generate_single_txt.sh"
    "migrate/txt/sanitize_txt.sh"
    "migrate/txt/scan_txt.sh"
    "migrate/txt/update_install_name_txt.sh"
    "migrate/txt/update_ip_txt.sh"
    
    "migrate/enable_migrate_config.sh"
    "migrate/get_migrate_app_name.sh"
    "migrate/initialize_migrate.sh"
)
