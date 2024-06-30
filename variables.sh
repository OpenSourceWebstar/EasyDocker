#!/bin/bash
trap exitScript SIGINT
# Directories are contained in init.sh

# Define text colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
PINK='\033[0;35m'
NC='\033[0m' # No Color

# Date/Time
backupDate=$(date  +'%F')
backupFolder="backup_$(date +"%Y%m%d%H%M%S")"
current_date=$(date +%Y-%m-%d)
current_time=$(date +%H:%M:%S)

# Domain/Network
public_ip_v4=$(curl -s https://api64.ipify.org?format=json | awk -F'"' '/ip/{print $4}')
server_nic="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"

# Files
docker_rooted_socket="/var/run/docker.sock"
swap_file=/swapfile
sysctl="/etc/sysctl.conf"
docker_log_file=easydocker.log
backup_log_file=backup.log
db_file=database.db
migrate_file=migrate.txt
run_file=run.txt

# Configs
update_done=false
app_categories_file=app_categories
ip_file=ips_hostname
config_file_backup=config_backup
config_file_general=config_general
config_file_requirements=config_requirements
config_file_wireguard=config_wireguard
config_files_all=("$app_categories_file" "$ip_file" "$config_file_backup" "$config_file_general" "$config_file_requirements" "$config_file_wireguard")

# Menu
menu_number=0

# Arrays
declare -a ufwd_port_array=()

#Secondary IP available : 10.8.1.126