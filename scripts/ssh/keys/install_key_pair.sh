#!/bin/bash

installSSHKeysForDownload()
{
    local flag="$1"
    if [[ "$SSHKEY_SETUP_NEEDED" == "true" ]]; then
        echo ""
        echo "############################################"
        echo "######        SSH Key Install         ######"
        echo "############################################"
        echo ""

        ssh_new_key="false"

        # Fix permissions for SSH Directory
        local result=$(sudo chmod 0775 "$ssh_dir" > /dev/null 2>&1)
        checkSuccess "Updating $ssh_dir with 0775 permissions."

        local result=$(sudo chown $docker_install_user:$docker_install_user "$ssh_dir" > /dev/null 2>&1)
        checkSuccess "Updating $ssh_dir with $docker_install_user ownership."

        # Check if SSH Keys are enabled
        if [[ "$CFG_REQUIREMENT_SSHKEY_ROOT" == "true" ]]; then
            generateSSHSetupKeyPair "root" $flag
        fi
        if [[ "$CFG_REQUIREMENT_SSHKEY_EASYDOCKER" == "true" ]]; then
            generateSSHSetupKeyPair "$sudo_user_name" $flag
        fi
        if [[ "$CFG_REQUIREMENT_SSHKEY_DOCKERINSTALL" == "true" ]]; then
            if [[ "$CFG_DOCKER_INSTALL_TYPE" == "rootless" ]]; then
                generateSSHSetupKeyPair "$CFG_DOCKER_INSTALL_USER" $flag
            fi
        fi

        if [[ "$CFG_REQUIREMENT_SSH_DISABLE_PASSWORDS" == "true" ]]; then
            disableSSHPasswords;
        fi
    fi
}
