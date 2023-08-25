#!/bin/bash

param1="$1"

repo_url="https://github.com/OpenSourceWebstar/EasyDocker"

# Directories
base_dir=/docker
install_path=$base_dir/containers/
ssl_dir=$base_dir/ssl/
ssh_dir=$base_dir/ssh/
backup_dir="$base_dir/backups"
backup_full_dir="$backup_dir/full"
backup_single_dir="$backup_dir/single"
backup_install_dir="$backup_dir/install"
restore_dir="$base_dir/restore"
restore_full_dir="$restore_dir/full"
restore_single_dir="$restore_dir/single"
# Install Scripts
script_dir="$base_dir/install/"
configs_dir="$script_dir/configs/"
resources_dir="$script_dir/resources/"
containers_dir="$script_dir/containers/"
scripts_dir="$script_dir/scripts/"
install_dir="$scripts_dir/install/"
logs_dir=$script_dir/logs/

initializeScript()
{
	# Check if script is run as root
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root."
		exit 1
	fi
	
	# Setup folder structure
	folders=("$base_dir" "$install_path" "$ssl_dir" "$ssh_dir" "$backup_dir" "$backup_full_dir" "$backup_single_dir" "$backup_install_dir" "$restore_dir" "$restore_full_dir" "$restore_single_dir" "$script_dir")
	for folder in "${folders[@]}"; do
		if [ ! -d "$folder" ]; then
			mkdir "$folder"
			echo "Folder '$folder' created."
		else
			echo "Folder '$folder' already exists."
		fi
	done

	# Update OS
	apt-get update
	apt-get upgrade -y
	echo "OS Updated"
	# Install Git
	apt-get install git -y
	echo "Git has been installed."

	# Git Clone and Update
	# Check if it's a Git repository by checking if it's inside a Git working tree
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "A Git repository is already cloned in '$script_dir'."
		echo "Please run the easydocker command to update the repository."
	else
		echo "No Git repository found. Cloning Git Repository."
		# Clone the Git repository into the specified directory
		git clone "$repo_url" "$script_dir"
		echo "Git repository cloned into '$script_dir'."
	fi

	# Custom command check
	if grep -q "easydocker" ~/.bashrc; then
		echo "Custom command 'easydocker' is already installed. You can already use 'easydocker'."
	else
		echo "Custom command 'easydocker' is not installed. Installing..."
		echo 'easydocker() {' >> ~/.bashrc
		echo '  path="$PWD"' >> ~/.bashrc
		echo '  cd /docker/install/ && chmod 0755 /docker/install/* && ./update.sh && ./start.sh "" "" "$path"' >> ~/.bashrc
		echo '}' >> ~/.bashrc
		source ~/.bashrc
		echo "Custom command 'easydocker' has been installed. You can now use 'easydocker'."
	fi
	# Future for a command maybe to link to here?
}

if [ "$param1" == "run" ]; then
	initializeScript;
fi