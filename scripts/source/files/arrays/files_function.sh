#!/bin/bash

function_scripts=(
    "function/checks/check_success.sh"
    "function/checks/detect_os.sh"
    "function/checks/user_exists.sh"
    "function/file/container/backup_files.sh"
    "function/file/container/restore_files.sh"
    "function/file/copy_file.sh"
    "function/file/copy_files.sh"
    "function/file/copy_resource.sh"
    "function/file/create_touch.sh"
    "function/file/empty_line/check_empty.sh"
    "function/file/empty_line/remove_line.sh"
    "function/file/move_file.sh"
    "function/file/zip_file.sh"
    "function/folder/copy_folder.sh"
    "function/folder/copy_folders.sh"
    "function/folder/create_folder.sh"
    "function/permission/app_folder.sh"
    "function/permission/before_start.sh"
    "function/permission/config.sh"
    "function/permission/easydocker_folders.sh"
    "function/permission/ownership/file.sh"
    "function/permission/ownership/folder_group.sh"
    "function/permission/ownership/root_file.sh"
    "function/permission/ownership/root_files_folders.sh"
    "function/run/reinstall_easydocker.sh"
    "function/validation/element.sh"
    "function/validation/email.sh"
    "function/validation/password.sh"
)