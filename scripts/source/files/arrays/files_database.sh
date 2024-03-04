#!/bin/bash

database_scripts=(
    "database/app/db_app_scan.sh"
    "database/app/db_cycle_apps.sh"
    "database/app/db_cycle_crontab.sh"
    "database/app/db_install_app.sh"
    "database/app/db_list_all_apps.sh"
    "database/app/db_list_installed_apps.sh"
    "database/app/db_uninstall_app.sh"

    "database/checks/db_check_port_open.sh"
    "database/checks/db_check_port_used.sh"

    "database/delete/db_delete_port_open.sh"
    "database/delete/db_delete_port_used.sh"
    "database/delete/db_port_port_open.sh"
    "database/delete/db_port_used_ports.sh"

    "database/get/db_get_ports_open_app.sh"
    "database/get/db_get_ports_open.sh"
    "database/get/db_get_ports_used_app.sh"
    "database/get/db_get_ports_used.sh"

    "database/insert/db_insert_backups.sh"
    "database/insert/db_insert_cron_jobs.sh"
    "database/insert/db_insert_option.sh"
    "database/insert/db_insert_path.sh"
    "database/insert/db_insert_port_open.sh"
    "database/insert/db_insert_port_used.sh"
    "database/insert/db_insert_restore.sh"
    "database/insert/db_insert_ssh_keys.sh"
    "database/insert/db_insert_ssh.sh"

    "database/tables/db_display_tables.sh"
    "database/tables/db_empty_table.sh"

    "database/check_os_update.sh"
    "database/delete_db_file.sh"
    "database/install_sqlite.sh"
)
