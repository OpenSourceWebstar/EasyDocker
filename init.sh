#!/bin/bash

param1="$1"

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
	sudo apt-get install git zip curl sshpass dos2unix apt-transport-https ca-certificates software-properties-common uidmap -y
	echo "SUCCESS: Prerequisite apps installed."

	if [[ "$param1" == "run" ]]; then
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
	fi

	if [[ "$param1" == "run" ]]; then
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
	fi

	if [[ "$param1" == "run" ]]; then
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
			sudo runuser -l  $sudo_user_name -c "git clone -q "$repo_url" "$script_dir""
			echo "SUCCESS: Git repository cloned into '$script_dir'."
		fi
	fi

	if [[ "$param1" == "run" ]]; then
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
			echo '    cd /docker/install/ && sudo chmod 0755 /docker/install/* && ./start.sh  "" "" "$path"' >> $sudo_bashrc
			echo '  else' >> $sudo_bashrc
			echo '    sudo sh -c "rm -rf /docker/install && cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run"' >> $sudo_bashrc
			echo '  fi' >> $sudo_bashrc
			echo '}' >> $sudo_bashrc
			source $sudo_bashrc
		else
			echo "SUCCESS: easydocker command already installed."
		fi
	fi

	if [[ "$param1" == "virtualmin" ]]; then
		virtualminReinstall;
	fi

	completeInitMessage $sudo_user_name;
}

virtualminInstall()
{
	echo ""
	echo "####################################################"
	echo "###      	      Virtualmin Install               ###"
	echo "####################################################"
	echo ""

	# Download the Virtualmin auto-install script
	cd / && wget https://software.virtualmin.com/gpl/scripts/virtualmin-install.sh

	# Make the script executable
	chmod +x virtualmin-install.sh

	# Run the Virtualmin auto-install script with sudo
	sudo ./virtualmin-install.sh -b LEMP # Using NGINX

	# Disable Firewalld
	#sudo systemctl stop firewalld
	#sudo systemctl disable firewalld
	#virtualmin disable-feature --all-domains --dns
	#echo "Disabled the firewalld & DNS service for EasyDocker"
	#sudo sed -i 's/80 default_server/8033 default_server/g' /etc/nginx/sites-available/default
	#echo "Changing port 80 to port 8033 for NGINX"
	#sudo systemctl restart nginx

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

	sudo systemctl start webmin

	echo ""
	echo "NOTICE - Now that Virtualmin is setup "
	echo ""
	#echo "NOTICE - In EasyDocker - Traefik will be used to handle the SSL certificate."
	#echo "NOTICE - In EasyDocker - Virtualmin Proxy will redirect Virtualmin traffic to Traefik."
	#echo ""
	#echo "TIP - You can also install Adguard or Pi-Hole to use as a DNS server for Virtualmin."
	#echo "TIP - You can setup a whitelist with Virtualmin Proxy for added security."
	#echo ""
	#echo "NOTICE - It's recommended to now install Traefik and Virtualmin Proxy through EasyDocker."
}

virtualminAskForFQDN()
{
	while true; do
		# Prompt the user for the domain they want to use with Virtualmin
		read -p "Enter the Fully Qualified Domain Name (FQDN) you'd like to use with Virtualmin (e.g. virtualmin.example.com): " domain_virtualmin

		# Check if the input appears to be a valid domain (FQDN)
		if [[ "$domain_virtualmin" =~ ^[a-zA-Z0-9.-]+\.[a-z]{2,}$ ]]; then
			break  # Valid format, exit the loop
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
	echo "###              Initial Questions               ###"
	echo "####################################################"
	echo ""
	echo "NOTICE - EasyDocker can work alongside Virtualmin"
	echo "Please only install if you need it"
	echo ""
	read -p "Do you want to install Virtualmin? (y/n): " install_virtualmin
	if [[ "$install_virtualmin" == [yY] ]]; then
		# Check if a valid subdomain is already stored in easydocker-fqdn.txt
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
}

virtualminEdits()
{
	echo ""
	echo "####################################################"
	echo "###               Virtualmin Edits               ###"
	echo "####################################################"
	echo ""
	if [[ "$install_virtualmin" == [yY] ]]; then

		local hostname="${domain_virtualmin%%.*}" # Before .
		local domain="${domain_virtualmin#*.}" # After .

		# hosts edits
        if [[ -f "$hosts_file" ]]; then
			sudo sed -i '/127.0.1.1/d' "$hosts_file"
			sudo sed -i "1i 127.0.1.1\t$hostname.$domain $hostname" $hosts_file
			echo "Hostname and FQDN added to the top of $hosts_file."
		else
			echo "No hostname file found...cancelling setup."
			return
		fi

		# hostname edits
        if [[ -f "$hostname_file" ]]; then
			# File updates
			echo "" | sudo tee $hostname_file
			echo "$domain_virtualmin" | sudo tee $hostname_file > /dev/null
			echo "Hostname updated to '$domain_virtualmin'."
			# Reload hostname
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
	if dpkg -l | grep -q virtualmin; then
		echo "For Virtualmin, please run 'easydocker' to finalize the setup."
		echo "Otherwise run 'sudo systemctl start'"
		echo ""
	fi
	echo "You can now use the 'easydocker' command under the $sudo_user_name."
	echo ""
	echo "Thank you & Enjoy! <3"
	echo ""
	exit
}

if [ "$param1" == "run" ] || [ "$param1" == "virtualmin" ]; then
	initializeScript;
fi