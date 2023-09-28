#!/bin/bash

source init.sh

source configs/config_backup
source configs/config_general
source configs/config_requirements

source scripts/variables.sh
source scripts/checks.sh
source scripts/menu.sh
source scripts/functions.sh
source scripts/update.sh
source scripts/docker.sh
source scripts/configs.sh
source scripts/whitelist.sh
source scripts/logs.sh
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

loadContainerFiles() {
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$(echo "$file" | sed 's|/docker/install//||')"
        fi
    done < <(sudo find "$install_containers_dir" -type d \( -name 'resources' \) -prune -o -type f \( -name '*.sh' \) -print0)
}
loadContainerFiles;

loadConfigFiles() {
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            source "$(echo "$file" | sed 's|/docker/install//||')"
        fi
    done < <(sudo find "$containers_dir" -type d \( -name 'resources' \) -prune -o -type f -name '*.config' -print0)
}
#loadConfigFiles;