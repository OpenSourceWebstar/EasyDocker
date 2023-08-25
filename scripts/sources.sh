#!/bin/bash

source init.sh
source update.sh

source configs/config_apps
source configs/config_backup
source configs/config_general
source configs/config_migrate
source configs/config_requirements
source configs/config_restore

source scripts/variables.sh
source scripts/checks.sh
source scripts/menu.sh
source scripts/functions.sh
source scripts/database.sh
source scripts/shutdown.sh

source scripts/backup.sh
source scripts/restore.sh
source scripts/migrate.sh

source scripts/install/install_os.sh
source scripts/install/install_docker.sh
source scripts/install/install_ufw.sh
source scripts/install/install_misc.sh
source scripts/install/install_user.sh
source scripts/install/install_ssh.sh

source scripts/install/install_apps_system.sh
source scripts/install/install_apps_privacy.sh
source scripts/install/install_apps_user.sh

source scripts/install/uninstall.sh

