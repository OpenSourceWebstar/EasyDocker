#!/bin/bash
trap exitScript SIGINT
appstorestart=()
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
public_ip_v4=$(curl -s https://api64.ipify.org?format=json | awk -F'"' '/ip/{print $4}')
server_nic="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"

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
config_file_wireguard=config_wireguard
config_files_all=("$ip_file" "$config_file_backup" "$config_file_general" "$config_file_requirements" "$config_file_wireguard")

# Docker
docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
docker_install_bashrc="/home/$CFG_DOCKER_INSTALL_USER/.bashrc"
docker_rootless_socket="$docker_rootless_socket"
docker_root_socket="/var/run/docker.sock"

# Menu
menu_number=0

#Secondary IP available : 10.8.1.126