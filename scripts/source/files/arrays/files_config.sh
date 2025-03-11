#!/bin/bash

config_scripts=(
    "config/application/edit_app.sh"
    "config/application/menu_apps.sh"
    "config/application/menu_category.sh"
    "config/application/missing_app_variables.sh"

    "config/docker/list_files.sh"
    "config/docker/menu.sh"

    "config/easydocker/config_setup_data.sh"
    "config/easydocker/config_to_container.sh"
    "config/easydocker/manage_menu.sh"
    "config/easydocker/missing_docker_variables.sh"
    "config/easydocker/missing_ips_hostname.sh"

    "config/password/generate_random_password.sh"
    "config/password/export_bcrypt_password.sh"
    "config/password/hash_password.sh"
    "config/password/process_bcrypt_password.sh"
    "config/password/replace_bcrypt_passwords.sh"
    "config/password/replace_plain_passwords.sh"
    "config/password/retreive_bcrypt_password.sh"
    "config/password/scan_file_for_random_pass.sh"
    "config/password/update_all.sh"

    "config/check_configs.sh"
    "config/main_menu.sh"
    "config/scan_variables.sh"
    "config/update_whitelist.sh"
)
