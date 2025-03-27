#!/bin/bash

restore_scripts=(
    "restore/file/decrypt/attempt_decrpytion.sh"
    "restore/file/decrypt/prompt_passphrase.sh"

    "restore/file/copy_restore_file.sh"
    "restore/file/extract_restore_file.sh"

    "restore/local/display_apps.sh"
    "restore/local/display_backups.sh"
    "restore/local/get_available_apps.sh"
    "restore/local/get_latest_backup.sh"
    "restore/local/restore_latest_backup.sh"
    "restore/local/select_application.sh"
    "restore/local/select_backup_file.sh"

    "restore/remote/remote_menu.sh"
    "restore/remote/select_app.sh"
    "restore/remote/select_backup_file.sh"
    "restore/remote/select_install_name.sh"
    "restore/remote/select_remote_location.sh"

    "restore/backup_list.sh"
    "restore/delete_docker_folder.sh"
    "restore/initialize_restore.sh"
    "restore/restore_clean_files.sh"
    "restore/start_restore.sh"
)
