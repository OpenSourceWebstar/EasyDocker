#!/bin/bash

installDisableSSHPassword()
{
    if [[ $CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS == "true" ]]; then
        # Check if already disabled
        if [[ $SSHKEY_DISABLE_PASS_NEEDED == "true" ]]; then
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
