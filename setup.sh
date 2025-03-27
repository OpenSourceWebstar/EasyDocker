#!/bin/bash

# Source "init.sh" and "variables.sh" if they exist, otherwise return an error
if [ -f "init.sh" ] && [ -f "variables.sh" ]; then
    source "init.sh"
    source "variables.sh"
else
    # Print an error message for any missing files
    [ ! -f "init.sh" ] && echo "Error: File 'init.sh' does not exist. Unable to source."
    [ ! -f "variables.sh" ] && echo "Error: File 'variables.sh' does not exist. Unable to source."
    echo "Files are missing, please run 'easydocker reset'"
    return 1
fi

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!" 
   exit 1
fi

# Domain Setup
while true; do
    read -p "Enter the Fully Qualified Domain Name (FQDN) you'd like to use with Virtualmin (e.g. example.com): " domain_virtualmin
    if [[ "$domain_virtualmin" =~ ^[a-zA-Z0-9.-]+\.[a-z]{2,}$ ]]; then
        break
    else
        echo "Invalid domain format. Please enter a valid Fully Qualified Domain Name (FQDN) (e.g. example.com)."
    fi
done

# Webmin Setup
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

install_virtualmin()
{
    echo ""
    echo "##########################################"
    echo "###      Start Install Virtualmin      ###"
    echo "##########################################"
    echo ""
    cd ~
    sudo rm -rf init.sh
    sudo apt-get install wget -y 
    sudo wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh 
    sudo chmod 0755 init.sh 
    ./init.sh virtualmin $domain_virtualmin $webmin_password
}

configure_virtualmin_1()
{
    echo ""
    echo "##########################################"
    echo "###      Configure Virtualmin 1        ###"
    echo "##########################################"
    echo ""
    # Disable email domain lookup server
    sudo virtualmin set-config --key mail_server_enabled --value 0
    # Disable ClamAV virus scanning
    sudo virtualmin set-config --key clamav_enabled --value 0
    # Enable MariaDB database server
    sudo virtualmin set-config --key mysql_enable --value 1
    # Disable PostgreSQL database server
    sudo virtualmin set-config --key postgresql_enable --value 0install_easydocker
    # Set MariaDB password to generated password
    sudo virtualmin set-config --key mysql_passmode --value 2  # 2 = Generated password
    # Set primary nameserver and skip resolvability check
    sudo virtualmin set-config --key primary_dns --value "retards.dev"
    sudo virtualmin set-config --key skip_resolvability_check --value 1
    # Set master admin's email address to default
    sudo virtualmin set-config --key admin_email --value ""
    # Set password storage mode to hashed passwords
    sudo virtualmin set-config --key passwd_mode --value 2  # 2 = Only store hashed passwords
    # Configure MariaDB for huge system
    sudo virtualmin set-config --key mysql_size --value "huge"
    # Set SSL certificate location to each domain’s home directory
    sudo virtualmin set-config --key ssl_cert_location --value 1  # 1 = In each domain's home directory
    # Mark post-install wizard as completed
    sudo virtualmin set-config --key wizard_run --value 1

    # Apply changes and restart services
    sudo virtualmin check-config
    systemctl restart webmin
    echo "Virtualmin post-comfig completed!"
}


install_easydocker()
{
    echo ""
    echo "##########################################"
    echo "###        Install EasyDocker          ###"
    echo "##########################################"
    echo ""
    cd ~
    sudo chmod 0755 init.sh
    ./init.sh init unattended
    su - easydocker -c 'source ~/.bashrc && easydocker run unattended'
    sudo sed -i "s|changeme.co.uk|$domain_virtualmin|" "$configs_dir/$config_file_general"
    sudo ufw stop
}

configure_virtualmin_2()
{
    echo ""
    echo "##########################################"
    echo "###      Configure Virtualmin 2        ###"
    echo "##########################################"
    echo ""
    DOMAINS=$(sudo virtualmin list-domains --name-only)
    EXTERNAL_IP=$(curl -s ifconfig.me)
    INTERNAL_IP=10.8.1.1

    sudo virtualmin set-ip --old $EXTERNAL_IP --new $INTERNAL_IP
    echo "Virtualmin IP Changed to $INTERNAL_IP!"

    for DOMAIN in $DOMAINS; do
        echo "Updating IP for $DOMAIN..."
        sudo virtualmin modify-domain --domain "$DOMAIN" --ip "$NEW_IP"
        echo "Virtualmin IP for domain $DOMAIN Changed to $INTERNAL_IP!"
    done

    sudo systemctl restart networking
    sudo systemctl restart nginx
}

setup_ufw_firewall()
{
    echo ""
    echo "##########################################"
    echo "###        Setup UFW Firewall          ###"
    echo "##########################################"
    echo ""

    # Disable firewalld
    sudo systemctl stop firewalld  
    sudo systemctl disable firewalld  
    sudo systemctl mask firewalld

    # Allow SSH access from anywhere
    sudo ufw allow 22/tcp

    sudo ufw allow from 10.8.0.0/24 to 10.8.1.0/24
    sudo ufw allow from 10.8.0.0/24 to 192.168.1.0/24
    sudo ufw allow from 10.8.1.0/24 to 10.8.0.0/24
    sudo ufw allow from 10.8.1.0/24 to 192.168.1.0/24
    sudo ufw allow from 192.168.1.0/24 to 10.8.0.0/24
    sudo ufw allow from 192.168.1.0/24 to 10.8.1.0/24

    # Allow DNS (TCP/UDP 53) on VPN (if needed)
    sudo ufw allow in on vpn to any port 53 proto tcp
    sudo ufw allow in on vpn to any port 53 proto udp

    # Enable the firewall
    sudo ufw enable
    sudo systemctl restart ufw
}

setup_backup_config()
{
    echo ""
    echo "##########################################"
    echo "###       Restore Configuration        ###"
    echo "##########################################"
    echo ""
    echo "In order to restore backup files, the config needs to be setup."
	while true; do
		read -p "Would you like to setup the backup config for restoring backups? (y/n): " backup_choice
		if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
                source "$configs_dir/$config_file_general"
                sudo $CFG_TEXT_EDITOR "$configs_dir/$config_file_general"
			break
		elif [[ "$backup_choice" =~ ^[Nn]$ ]]; then
			echo "Skipping backup setup." && break
		else
			echo "Please answer y (yes) or n (no)."
		fi
	done

}

restore_virtualmin_backups()
{
	while true; do
		read -p "Please enter the Virtualmin restore server name ? (y/n): " backup_choice
		if [[ "$backup_choice" =~ ^[Yy]$ ]]; then
                source /docker/configs/general_config
                sudo $CFG_TEXT_EDITOR "/docker/configs/config_backup"
			break
		elif [[ "$backup_choice" =~ ^[Nn]$ ]]; then
			echo "Skipping download." && break
		else
			echo "Please answer y (yes) or n (no)."
		fi
	done
    su - easydocker -c 'source ~/.bashrc && easydocker restore virtualmin all'
}

restore_easydocker_backups()
{

}

install_virtualmin;
configure_virtualmin_1;
install_easydocker;
configure_virtualmin_2;
setup_ufw_firewall;
setup_backup_config;
restore_virtualmin_backups;
restore_easydocker_backups;
