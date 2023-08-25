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
#domain_prefix=$hostname
#domain_var_name="CFG_DOMAIN_${domain_number}"
#domain_full=$(grep "^$domain_var_name=" $configs_dir/config_general | cut -d '=' -f 2-)
#host_setup=${domain_prefix}.${domain_full}

# Files
docker_log_file=easydocker.log
backup_log_file=backup.log
db_file=database.db
ip_file=ips_hostname
ssl_key=${domain_full}.key
ssl_crt=${domain_full}.crt
swap_file=/swapfile


# Configs
config_file_apps=config_apps
config_file_backup=config_backup
config_file_general=config_general
config_file_migrate=config_migrate
config_file_requirements=config_requirements
config_file_restore=config_restore

# Menu
menu_number=0

#Secondary IP available : 10.8.1.120