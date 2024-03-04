#!/bin/bash

crontab_scripts=(
    "crontab/app/check_backup_app.sh"
    "crontab/app/install/setup.sh"
    "crontab/app/install/timing.sh"
    "crontab/app/remove_backup_app.sh"
    "crontab/app/remove_folder.sh"
    "crontab/clear_crontab.sh"
    "crontab/install_crontab.sh"
)
