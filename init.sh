#!/bin/bash

param1="$1" # init / virtualmin
param2="$2" # unattended / domain
param3="$3" # / webmin_password

install_param="init"
sudo_user_name=easydocker
repo_url="https://github.com/OpenSourceWebstar/EasyDocker"
sshd_config="/etc/ssh/sshd_config"
sudo_bashrc="/home/$sudo_user_name/.bashrc"
hosts_file="/etc/hosts"
hostname_file="/etc/hostname"
fqdn_file="/root/easydocker-fqdn.txt"

# Directories
docker_dir="/docker"
containers_dir="$docker_dir/containers/"
ssl_dir="$docker_dir/ssl/"
ssh_dir="$docker_dir/ssh/"
wireguard_dir="$docker_dir/wireguard/"
logs_dir="$docker_dir/logs/"
configs_dir="$docker_dir/configs/"
backup_dir="$docker_dir/backups"
backup_single_dir="$backup_dir/single"
backup_install_dir="$backup_dir/install"
restore_dir="$docker_dir/restore"
restore_single_dir="$restore_dir/single"
migrate_dir="$docker_dir/migrate"
migrate_single_dir="$migrate_dir/single"
# Install Scripts
script_dir="$docker_dir/install"
install_configs_dir="$script_dir/configs/"
install_containers_dir="$script_dir/containers/"
install_scripts_dir="$script_dir/scripts/"
# Virtualmin
vm_backup_dir="/backups/"


initializeScript()
{
	if [[ $EUID -ne 0 ]]; then
		echo "This script must be run as root."
		exit 1
	fi

	if [[ "$param1" == "virtualmin" ]]; then
		virtualminQuestions;
	fi

	echo ""
	echo "####################################################"
	echo "###          Updating Operating System           ###"
	echo "####################################################"
	echo ""
	apt-get install sudo -y
	sudo apt-get update
	sudo apt-get dist-upgrade -y

	if [[ "$param1" == "virtualmin" ]]; then
		virtualminEdits;
	fi

	echo "SUCCESS: OS Updated"

	echo ""
	echo "####################################################"
	echo "###         Installing Prerequired Apps          ###"
	echo "####################################################"
	echo ""
	sudo apt-get install git zip curl sshpass dos2unix dnsutils apt-transport-https ca-certificates software-properties-common uidmap jq -y
	TARGET_PATH="/usr/sbin"
	CONFIG_FILE="$HOME/.bashrc"
	if ! echo "$PATH" | grep -q "$TARGET_PATH"; then
		echo "Adding $TARGET_PATH to PATH..."
		echo "export PATH=\$PATH:$TARGET_PATH" >> "$CONFIG_FILE"
		source "$CONFIG_FILE"
		echo "PATH updated successfully!"
	else
		echo "$TARGET_PATH is already in PATH."
	fi
	echo "SUCCESS: Prerequisite apps installed."

	if [[ "$param1" == "$install_param" ]]; then
		echo ""
		echo "####################################################"
		echo "###             Installing Docker                ###"
		echo "####################################################"
		echo ""
		if command -v docker &> /dev/null; then
		    echo "SUCCESS: Docker is already installed."
		else
			curl -fsSL https://get.docker.com | sh
			systemctl start docker
			systemctl enable docker
			echo "SUCCESS: Docker has been installed successfully."
		fi
	fi

	if [[ "$param1" == "$install_param" ]]; then
		echo ""
		echo "####################################################"
		echo "###           Creating User Accounts             ###"
		echo "####################################################"
		echo ""
		if id "$sudo_user_name" &>/dev/null; then
			echo "SUCCESS: User $sudo_user_name already exists."
		else
			useradd -s /bin/bash -d "/home/$sudo_user_name" -m -G sudo "$sudo_user_name"
			echo "Setting password for $sudo_user_name user."
			passwd $sudo_user_name
			usermod -aG docker "$sudo_user_name"
			systemctl restart docker
			echo "SUCCESS: User $sudo_user_name created successfully."
		fi
		local sudoers_file="/etc/sudoers"
		local sudo_entry="$sudo_user_name ALL=(ALL) NOPASSWD: ALL"
		if ! grep -q "$sudo_entry" $sudoers_file; then
			echo "" | sudo tee -a "$sudoers_file" > /dev/null
			echo "$sudo_entry" | sudo tee -a "$sudoers_file" > /dev/null
			sudo visudo -c
			echo "SUCCESS: Added passwordless sudo entry for user $sudo_user_name."
		else
			echo "SUCCESS: Passwordless sudo entry already setup."
		fi
	fi

	if [[ "$param1" == "$install_param" ]]; then
		echo ""
		echo "####################################################"
		echo "###        EasyDocker Folder Creation            ###"
		echo "####################################################"
		echo ""
		folders=("$docker_dir" "$containers_dir" "$ssl_dir" "$ssh_dir" "$wireguard_dir" "$logs_dir" "$configs_dir" "$backup_dir" "$backup_single_dir" "$backup_install_dir" "$restore_dir" "$restore_single_dir" "$migrate_dir" "$migrate_single_dir"  "$script_dir")
		for folder in "${folders[@]}"; do
			if [ ! -d "$folder" ]; then
				sudo mkdir "$folder"
				sudo chown $sudo_user_name:$sudo_user_name "$folder"
				sudo chmod 750 "$folder"
				echo "SUCCESS: Folder '$folder' created."
			fi
		done
		echo "SUCCESS: All folders have been created."
	fi

	if [[ "$param1" == "$install_param" ]]; then
		echo ""
		echo "####################################################"
		echo "###      	      Git Clone / Update            ###"
		echo "####################################################"
		echo ""
		if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
			echo "A Git repository is already cloned in '$script_dir'."
			echo "NOTICE: Please run the easydocker command to update the repository."
		else
			echo "NOTICE: No Git repository found. Cloning Git Repository."
			sudo runuser -l  $sudo_user_name -c "git clone -q "$repo_url" "$script_dir""
			echo "SUCCESS: Git repository cloned into '$script_dir'."
		fi
	fi

	if [[ "$param1" == "$install_param" ]]; then
		setupEasyDockerCommand;
	fi

	if [[ "$param1" == "virtualmin" ]]; then
		virtualminReinstall;
	fi

	completeInitMessage $sudo_user_name;
}

setupEasyDockerCommand()
{
	echo ""
	echo "####################################################"
	echo "###           Custom Command Setup           ###"
	echo "####################################################"
	echo ""
	if ! grep -q "EasyDocker Command Start" $sudo_bashrc; then
		echo "NOTICE: Command maker not found. Removing old EasyDocker command."
		sed -i '/^easydocker() {$/,/^}$/d' $sudo_bashrc
	else
		echo "NOTICE: Command maker found. Removing old EasyDocker command."
		sed -i '/# EasyDocker Command Start/,/# EasyDocker Command End/d' $sudo_bashrc
	fi
	echo "NOTICE: Custom command 'easydocker' is not installed. Installing..."
	echo '# EasyDocker Command Start' >> $sudo_bashrc
	echo '# EasyDocker Command Version 1.1' >> $sudo_bashrc
	echo 'easydocker()' >> $sudo_bashrc
	echo '{' >> $sudo_bashrc
	echo '  local command1="$1"; if [[ "$command1" == "" ]]; then command1="empty"; fi' >> $sudo_bashrc
	echo '  local command2="$2"; if [[ "$command2" == "" ]]; then command2="empty"; fi' >> $sudo_bashrc
	echo '  local command3="$3"; if [[ "$command3" == "" ]]; then command3="empty"; fi' >> $sudo_bashrc
	echo '  local command4="$4"; if [[ "$command4" == "" ]]; then command4="empty"; fi' >> $sudo_bashrc
	echo '  local command5="$5"; if [[ "$command5" == "" ]]; then command5="empty"; fi' >> $sudo_bashrc
	echo '  local path="$PWD"' >> $sudo_bashrc
	echo '  if [[ $command1 == "reset" ]]; then' >> $sudo_bashrc
	echo '    sudo sh -c "rm -rf /docker/install && rm -rf ~/init.sh && apt-get install wget -y && wget -O ~/init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 ~/init.sh && ~/init.sh '"$install_param"'"' >> $sudo_bashrc
	echo '  elif [ -f "/docker/install/start.sh" ]; then' >> $sudo_bashrc
	echo '    sudo chmod 0755 /docker/install/* && cd /docker/install && ./start.sh "$command1" "$command2" "$command3" "$command4" "$command5"  "$command6" "$command7" "$command8" "$command9" "$path"' >> $sudo_bashrc
	echo '  else' >> $sudo_bashrc
	echo '    sudo sh -c "rm -rf /docker/install && rm -rf ~/init.sh && apt-get install wget -y && wget -O ~/init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 ~/init.sh && ~/init.sh '"$install_param"'"' >> $sudo_bashrc
	echo '  fi' >> $sudo_bashrc
	echo '}' >> $sudo_bashrc
	echo '# EasyDocker Command End' >> $sudo_bashrc
	source $sudo_bashrc
}

virtualminInstall()
{
	echo ""
	echo "####################################################"
	echo "###      	      Virtualmin Install               ###"
	echo "####################################################"
	echo ""

	cd / && wget https://software.virtualmin.com/gpl/scripts/virtualmin-install.sh
	chmod +x virtualmin-install.sh
	if [[ "$param2" != "unattended" ]]; then
		sudo ./virtualmin-install.sh -b LEMP
	else
		export VIRTUALMIN_NONINTERACTIVE=1
		sudo ./virtualmin-install.sh --force --setup --minimal --bundle LEMP --hostname $param2
	fi

	if [[ "$param3" == "" ]]; then
		while true; do
			read -s -p "Enter the new password for the 'root' Webmin user: " webmin_password
			if [ -n "$webmin_password" ] && [ ${#webmin_password} -ge 8 ]; then
				sudo /usr/share/webmin/changepass.pl /etc/webmin root "$webmin_password"
				sudo systemctl stop webmin
				echo "Password changed and Webmin restarted successfully."
				break
			else
				echo "Password is too short or empty. Please provide a password with at least 8 characters."
			fi
		done
	else
		sudo /usr/share/webmin/changepass.pl /etc/webmin root "$param3"
		sudo systemctl stop webmin
		echo "Password changed and Webmin restarted successfully."
	fi

	sudo systemctl start webmin

	echo ""
	echo "NOTICE - Now that Virtualmin is setup "
	echo ""
}

virtualminAskForFQDN()
{
	while true; do
		read -p "Enter the Fully Qualified Domain Name (FQDN) you'd like to use with Virtualmin (e.g. virtualmin.example.com): " domain_virtualmin
		if [[ "$domain_virtualmin" =~ ^[a-zA-Z0-9.-]+\.[a-z]{2,}$ ]]; then
			break
		else
			echo "Invalid domain format. Please enter a valid Fully Qualified Domain Name (FQDN) (e.g. virtualmin.example.com)."
		fi
	done
}

virtualminCreateFQDNFile()
{
	touch "$fqdn_file"
	echo "$domain_virtualmin" > "$fqdn_file"
}

virtualminQuestions()
{
	echo ""
	echo "####################################################"
	echo "###              Initial Setup                   ###"
	echo "####################################################"
	echo ""
	echo "NOTICE - EasyDocker can work alongside Virtualmin"
	echo "Please only install if you need it"
	echo ""

	if [[ "$param2" == "" ]]; then
		read -p "Do you want to install Virtualmin? (y/n): " install_virtualmin
		if [[ "$install_virtualmin" == [yY] ]]; then
			if [[ -f "$fqdn_file" ]]; then
				existing_subdomain=$(head -n 1 "$fqdn_file")
				if [ -n "$existing_subdomain" ]; then
					while true; do
						echo ""
						echo "NOTICE - An existing subdomain is configured: $existing_subdomain"
						echo ""
						echo "QUESTION : Would you like to use $existing_subdomain for your subdomain? (y/n): "
						read -p "" reinstall_virtualmin_choice
						if [[ -n "$reinstall_virtualmin_choice" ]]; then
							break
						fi
						isNotice "Please provide a valid input."
					done
					if [[ "$reinstall_virtualmin_choice" == [yY] ]]; then
						domain_virtualmin="$existing_subdomain"
					fi
					if [[ "$reinstall_virtualmin_choice" == [nN] ]]; then
						virtualminAskForFQDN;
					fi
				else
					virtualminAskForFQDN;
				fi
			else
				virtualminAskForFQDN;
				virtualminCreateFQDNFile;
			fi
		fi
	else
		install_virtualmin=y
	fi
}

virtualminEdits()
{
	echo ""
	echo "####################################################"
	echo "###               Virtualmin Edits               ###"
	echo "####################################################"
	echo ""
	if [[ "$install_virtualmin" == [yY] ]]; then
		local hostname="${domain_virtualmin%%.*}"
		local domain="${domain_virtualmin#*.}"
        if [[ -f "$hosts_file" ]]; then
			sudo sed -i '/127.0.1.1/d' "$hosts_file"
			sudo sed -i "1i 127.0.1.1\t$hostname.$domain $hostname" $hosts_file
			echo "Hostname and FQDN added to the top of $hosts_file."
		else
			echo "No hostname file found...cancelling setup."
			return
		fi
        if [[ -f "$hostname_file" ]]; then
			echo "" | sudo tee $hostname_file
			echo "$domain_virtualmin" | sudo tee $hostname_file > /dev/null
			echo "Hostname updated to '$domain_virtualmin'."
			sudo hostnamectl set-hostname $(cat $hostname_file)
			echo "Reloaded hostname file"
		else
			echo "No hostname file found...cancelling setup."
			return
		fi
	fi
}

virtualminReinstall()
{
	if [[ "$install_virtualmin" == [yY] ]]; then
		if dpkg -l | grep -q virtualmin; then
			while true; do
				echo ""
				echo "NOTICE - Virtualmin install already found."
				echo ""
				echo "QUESTION : Would you like to reinstall Virtualmin? (y/n): "
				read -p "" reinstall_virtualmin_choice
				if [[ -n "$reinstall_virtualmin_choice" ]]; then
					break
				fi
				isNotice "Please provide a valid input."
			done
			if [[ "$reinstall_virtualmin_choice" == [yY] ]]; then
				virtualminInstall;
			fi
		else
			virtualminInstall;
		fi
	fi
}

completeInitMessage()
{
	local sudo_user_name="$1"
	echo ""
	echo "####################################################"
	echo "###      EasyDocker Initilization Complete       ###"
	echo "####################################################"
	echo ""

	if [[ "$param2" == "" ]]; then
		while true; do
			echo ""
			echo "NOTICE - It is recommended to restart the system upon initial install."
			echo ""
			echo "QUESTION : Would you like to restart your system as recommended? (y/n): "
			read -p "" restart_after_install_choice
			if [[ -n "$restart_after_install_choice" ]]; then
				break
			fi
			isNotice "Please provide a valid input."
		done
		if [[ "$restart_after_install_choice" == [yY] ]]; then
			if dpkg -l | grep -q virtualmin; then
				echo "For Virtualmin, please run 'easydocker' to finalize the setup."
				echo "Otherwise run 'sudo systemctl start'"
				echo ""
			fi
			echo "You can now use the 'easydocker' command under the $sudo_user_name."
			echo ""
			echo "Thank you & Enjoy! <3"
			echo ""
			sudo reboot
		fi
	fi
}

if [ "$param1" == "$install_param" ] || [ "$param1" == "virtualmin" ]; then
	initializeScript;
fi