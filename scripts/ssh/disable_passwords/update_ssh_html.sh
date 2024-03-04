#!/bin/bash

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
