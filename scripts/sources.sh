#!/bin/bash

source init.sh

source configs/config_backup
source configs/config_general
source configs/config_requirements

source scripts/variables.sh
source scripts/checks.sh
source scripts/menu.sh
source scripts/functions.sh
source scripts/permissions.sh
source scripts/database.sh
source scripts/network.sh
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

source scripts/install/uninstall.sh

loadContainerFiles