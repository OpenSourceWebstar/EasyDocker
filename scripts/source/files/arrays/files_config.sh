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

    "config/password/update_all.sh"
    "config/password/update_file.sh"

    "config/main_menu.sh"
    "config/scan_variables.sh"
    "config/update_whitelist.sh"
)
