#!/bin/bash
trap exitScript SIGINT
# Directories are contained in init.sh

# Define text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE="\033[1;34m"
PINK="\e[35m"
NC='\033[0m' # No Color

# Date/Time
backupDate=$(date  +'%F')
backupFolder="backup_$(date +"%Y%m%d%H%M%S")"
current_date=$(date +%Y-%m-%d)
current_time=$(date +%H:%M:%S)

# Domain/Network
public_ip=$(hostname -I | awk '{print $1}')

# Files
swap_file=/swapfile
sysctl="/etc/sysctl.conf"
docker_log_file=easydocker.log
backup_log_file=backup.log
db_file=database.db
migrate_file=migrate.txt

# Configs
update_done=false
ip_file=ips_hostname
config_file_backup=config_backup
config_file_general=config_general
config_file_requirements=config_requirements
config_files_all=("$ip_file" "$config_file_backup" "$config_file_general" "$config_file_requirements")

# Menu
menu_number=0

#Secondary IP available : 10.8.1.121