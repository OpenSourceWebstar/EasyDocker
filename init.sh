#!/bin/bash

param1="$1"

sudo_user_name=easydocker
repo_url="https://github.com/OpenSourceWebstar/EasyDocker"
sshd_config="/etc/ssh/sshd_config"
sudo_bashrc="/home/$sudo_user_name/.bashrc"

# Directories
base_dir=/docker
install_dir=$base_dir/containers/
ssl_dir=$base_dir/ssl/
ssh_dir=$base_dir/ssh/
backup_dir="$base_dir/backups"
backup_full_dir="$backup_dir/full"
backup_single_dir="$backup_dir/single"
backup_install_dir="$backup_dir/install"
restore_dir="$base_dir/restore"
restore_full_dir="$restore_dir/full"
restore_single_dir="$restore_dir/single"
migrate_dir="$base_dir/migrate"
migrate_full_dir="$migrate_dir/full"
migrate_single_dir="$migrate_dir/single"
# Install Scripts
script_dir="$base_dir/install"
configs_dir="$script_dir/configs/"
containers_dir="$script_dir/containers/"
scripts_dir="$script_dir/scripts/"
logs_dir=$script_dir/logs/

initializeScript()
{
	# Check if script is run as root
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root."
		exit 1
	fi
	
	# Update OS
	apt-get update
	apt-get upgrade -y
	echo "OS Updated"

	# Install Apps
	apt-get install sudo git zip curl sshpass dos2unix apt-transport-https ca-certificates software-properties-common uidmap -y
	echo "Prerequisite apps installed."

	# Create Users
	if id "$sudo_user_name" &>/dev/null; then
		echo "User $sudo_user_name already exists."
	else
		# If the user doesn't exist, create the user
		useradd -s /bin/bash -d "/home/$sudo_user_name" -m -G sudo "$sudo_user_name"
		echo "Setting password for $sudo_user_name user."
		passwd $sudo_user_name
		echo "User $sudo_user_name created successfully."
	fi

	# Setup folder structure
	folders=("$base_dir" "$install_dir" "$ssl_dir" "$ssh_dir" "$backup_dir" "$backup_full_dir" "$backup_single_dir" "$backup_install_dir" "$restore_dir" "$restore_full_dir" "$restore_single_dir" "$migrate_dir" "$migrate_full_dir" "$migrate_single_dir"  "$script_dir")
	for folder in "${folders[@]}"; do
		if [ ! -d "$folder" ]; then
			sudo mkdir "$folder"
			sudo chown $sudo_user_name:$sudo_user_name "$folder"
			sudo chmod 750 "$folder"
			echo "Folder '$folder' created."
		else
			echo "Folder '$folder' already exists."
		fi
	done

	# Git Clone and Update
	# Check if it's a Git repository by checking if it's inside a Git working tree
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "A Git repository is already cloned in '$script_dir'."
		echo "Please run the easydocker command to update the repository."
	else
		echo "No Git repository found. Cloning Git Repository."
		# Clone the Git repository into the specified directory
		runuser -l  $sudo_user_name -c "git clone "$repo_url" "$script_dir""
		echo "Git repository cloned into '$script_dir'."
	fi

	# Custom command check
	if grep -q "easydocker" $sudo_bashrc; then
		echo ""
		echo ""
		echo "Custom command 'easydocker' is already installed. You can already use 'easydocker'."
		echo ""
		echo "You can now use the command under the $sudo_user_name."
	else
		echo "Custom command 'easydocker' is not installed. Installing..."
		echo 'easydocker() {' >> $sudo_bashrc
		echo '  path="$PWD"' >> $sudo_bashrc
		echo '  cd /docker/install/ && chmod 0755 /docker/install/* && ./start.sh  "" "" "$path"' >> $sudo_bashrc
		echo '}' >> $sudo_bashrc
		source $sudo_bashrc
		echo ""
		echo "Custom command 'easydocker' has been installed."
		echo ""
		echo "You can now use the command under the $sudo_user_name."
	fi	
}

if [ "$param1" == "run" ]; then
	initializeScript;
fi