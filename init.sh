#!/bin/bash

param1="$1"

sudo_user_name=easydocker
repo_url="https://github.com/OpenSourceWebstar/EasyDocker"
sshd_config="/etc/ssh/sshd_config"
sudo_bashrc="/home/$sudo_user_name/.bashrc"

# Directories
docker_dir="/docker"
containers_dir="$docker_dir/containers/"
ssl_dir="$docker_dir/ssl/"
ssh_dir="$docker_dir/ssh/"
logs_dir="$docker_dir/logs/"
configs_dir="$docker_dir/configs/"
backup_dir="$docker_dir/backups"
backup_full_dir="$backup_dir/full"
backup_single_dir="$backup_dir/single"
backup_install_dir="$backup_dir/install"
restore_dir="$docker_dir/restore"
restore_full_dir="$restore_dir/full"
restore_single_dir="$restore_dir/single"
migrate_dir="$docker_dir/migrate"
migrate_full_dir="$migrate_dir/full"
migrate_single_dir="$migrate_dir/single"
# Install Scripts
script_dir="$docker_dir/install"
install_configs_dir="$script_dir/configs/"
install_containers_dir="$script_dir/containers/"
install_scripts_dir="$script_dir/scripts/"

initializeScript()
{
	# Check if script is run as root
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root."
		exit 1
	fi

	echo ""
	echo "####################################################"
	echo "###          Updating Operating System           ###"
	echo "####################################################"
	echo ""
	apt-get update
	apt-get upgrade -y
	echo "SUCCESS: OS Updated"

	echo ""
	echo "####################################################"
	echo "###         Installing Prerequired Apps          ###"
	echo "####################################################"
	echo ""
	apt-get install sudo git zip curl sshpass dos2unix apt-transport-https ca-certificates software-properties-common uidmap -y
	echo "SUCCESS: Prerequisite apps installed."

	echo ""
	echo "####################################################"
	echo "###           Creating User Accounts             ###"
	echo "####################################################"
	echo ""
	if id "$sudo_user_name" &>/dev/null; then
		echo "SUCCESS: User $sudo_user_name already exists."
	else
		# If the user doesn't exist, create the user
		useradd -s /bin/bash -d "/home/$sudo_user_name" -m -G sudo "$sudo_user_name"
		echo "Setting password for $sudo_user_name user."
		passwd $sudo_user_name
		echo "SUCCESS: User $sudo_user_name created successfully."
	fi

	echo ""
	echo "####################################################"
	echo "###        EasyDocker Folder Creation            ###"
	echo "####################################################"
	echo ""
	# Setup folder structure
	folders=("$docker_dir" "$containers_dir" "$ssl_dir" "$ssh_dir" "$logs_dir" "$configs_dir" "$backup_dir" "$backup_full_dir" "$backup_single_dir" "$backup_install_dir" "$restore_dir" "$restore_full_dir" "$restore_single_dir" "$migrate_dir" "$migrate_full_dir" "$migrate_single_dir"  "$script_dir")
	for folder in "${folders[@]}"; do
		if [ ! -d "$folder" ]; then
			sudo mkdir "$folder"
			sudo chown $sudo_user_name:$sudo_user_name "$folder"
			sudo chmod 750 "$folder"
			echo "SUCCESS: Folder '$folder' created."
		#else
			#echo "Folder '$folder' already exists."
		fi
	done
	echo "SUCCESS: All folders have been created."

	echo ""
	echo "####################################################"
	echo "###      	       Git Clone / Update              ###"
	echo "####################################################"
	echo ""
	# Git Clone and Update
	# Check if it's a Git repository by checking if it's inside a Git working tree
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo "A Git repository is already cloned in '$script_dir'."
		echo "NOTICE: Please run the easydocker command to update the repository."
	else
		echo "NOTICE: No Git repository found. Cloning Git Repository."
		# Clone the Git repository into the specified directory
		runuser -l  $sudo_user_name -c "git clone -q "$repo_url" "$script_dir""
		echo "SUCCESS: Git repository cloned into '$script_dir'."
	fi

	echo ""
	echo "####################################################"
	echo "###      	     Custom Command Setup              ###"
	echo "####################################################"
	echo ""
	# Custom command check
	if ! grep -q "easydocker" $sudo_bashrc; then
		echo "NOTICE: Custom command 'easydocker' is not installed. Installing..."
		echo 'easydocker() {' >> $sudo_bashrc
		echo '  if [ -f "/docker/install/start.sh" ]; then' >> $sudo_bashrc
		echo '    local path="$PWD"' >> $sudo_bashrc
		echo '    cd /docker/install/ && chmod 0755 /docker/install/* && ./start.sh  "" "" "$path"' >> $sudo_bashrc
		echo '  else' >> $sudo_bashrc
		echo '    sudo sh -c "rm -rf /docker/install && cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run"' >> $sudo_bashrc
		echo '  fi' >> $sudo_bashrc
		echo '}' >> $sudo_bashrc
		source $sudo_bashrc
	else
		echo "SUCCESS: easydocker command already installed."
	fi

	echo ""
	echo "####################################################"
	echo "###      EasyDocker Initilization Complete       ###"
	echo "####################################################"
	echo ""
	echo "You can now use the easydocker command under the $sudo_user_name."
	echo ""
	echo "Enjoy!"
	echo ""
	exit
}

if [ "$param1" == "run" ]; then
	initializeScript;
fi