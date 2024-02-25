#!/bin/bash

disableSSHPasswordFunction()
{
    if [[ $CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS == "true" ]]; then
        # Check if already disabled
        if grep -q "PasswordAuthentication no" $sshd_config; then
            isSuccessful "Password Authentication is already disabled."
        else
            while true; do
                echo ""
                isQuestion "Do you want to disable SSH password logins? (y/n): "
                read -p "" disable_ssh_passwords
                case "$disable_ssh_passwords" in
                    [Yy]*)
                        local backup_file="$sshd_config_backup_$current_date-$current_time"
                        result=$(sudo cp $sshd_config "$backup_file")
                        checkSuccess "Backup sshd_config file"

                        result=$(sudo sed -i '/^PasswordAuthentication/d' $sshd_config)
                        checkSuccess "Removing existing PasswordAuthentication lines"

                        result=$(echo "PasswordAuthentication no" | sudo tee -a $sshd_config)
                        checkSuccess "Add new PasswordAuthentication line at the end of sshd_config"

                        result=$(sudo systemctl restart sshd)
                        checkSuccess "Restart SSH service"
                        break
                        ;;
                    [Nn]*)
                        while true; do
                            isQuestion "Do you want to stop being asked to disable SSH Password logins? (y/n): "
                            read -rp "" sshdisablepasswordask
                            if [[ "$sshdisablepasswordask" =~ ^[yYnN]$ ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input (y/n)."
                        done
                        if [[ "$sshdisablepasswordask" == [yY] ]]; then
                            local config_file="$configs_dir$config_file_requirements"
                            result=$(sudo sed -i 's/CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS=true/CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS=false/' $config_file)
                            checkSuccess "Disabled CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS in the $config_file_requirements config."
                            source $config_file
                        fi
                        break
                        ;;
                    *)
                        echo "Please enter 'y' or 'n'."
                        ;;
                esac
            done
        fi
    fi
}

updateSSHHTMLSSHKeyLinks() 
{
    local index_file="index.html"
    local private_path="${ssh_dir}private/"

    local root_user_key="${CFG_INSTALL_NAME}_sshkey_root"
    local sudo_user_key="${CFG_INSTALL_NAME}_sshkey_${sudo_user_name}"
    local install_user_key="${CFG_INSTALL_NAME}_sshkey_${CFG_DOCKER_INSTALL_USER}"

    if [ -f "$private_path$index_file" ]; then
        # Reset all links to placeholders
        result=$(sudo sed -i "s|<a href=\"$root_user_key\">User - Root's SSH Key</a>|<!--LINK1-->|" $private_path$index_file)
        checkSuccess "Resetting Root URL to empty."

        result=$(sudo sed -i "s|<a href=\"$sudo_user_key\">User - Easydocker's SSH Key</a>|<!--LINK2-->|" $private_path$index_file)
        checkSuccess "Resetting Easydocker URL to empty."

        result=$(sudo sed -i "s|<a href=\"$install_user_key\">User - Dockerinstall's SSH Key</a>|<!--LINK3-->|" $private_path$index_file)
        checkSuccess "Resetting Dockerinstall URL to empty."

        # Check and update links based on the presence of key files
        if [ -f "$private_path$root_user_key" ]; then
            result=$(sudo sed -i "s|<!--LINK1-->|<a href=\"$root_user_key\" download>Download Root's SSH Key</a>|" $private_path$index_file)
            checkSuccess "Root SSH Key found, updating the index.html for download link."
        fi

        if [ -f "$private_path$sudo_user_key" ]; then
            result=$(sudo sed -i "s|<!--LINK2-->|<a href=\"$sudo_user_key\" download>Download Easydocker's SSH Key</a>|" $private_path$index_file)
            checkSuccess "Easydocker SSH Key found, updating the index.html for download link."
        fi

        if [ -f "$private_path$install_user_key" ]; then
            result=$(sudo sed -i "s|<!--LINK3-->|<a href=\"$install_user_key\" download>Download Dockerinstall's SSH Key</a>|" $private_path$index_file)
            checkSuccess "Dockerinstall SSH Key found, updating the index.html for download link."
        fi
    fi
}
