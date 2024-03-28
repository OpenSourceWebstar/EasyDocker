#!/bin/bash

disableSSHPasswords()
{
    echo ""
    isNotice "!!!!!!!!!!!!!!!! ***PROCEED WITH CAUTION*** !!!!!!!!!!!!!!!"
    echo ""
    isNotice "You are about to disable SSH Passwords Potentially blocking you out of your system!!!!"
    isNotice "Make sure you have downloaded and tested your SSH keys before disabling password login!!!"
    echo ""
    isNotice "The reason we disable ssh passwords is to improve security, allowing only SSH Key logins"
    isNotice "You will still be able to log in with SSH passwords via physical/console access, just not remotely!"
    echo ""
    # Define an array to store users without SSH keys
    users_without_keys=()

    # SSH Keys
    if [[ $CFG_REQUIREMENT_SSHKEY_ROOT == "true" ]]; then
        if checkSSHSetupKeyPair "root"; then
            isSuccessful "The SSH Key(s) for root appears to be set up."
        else
            isNotice "An SSH Key for root is not found, are you sure you want to disable SSH passwords?"
            users_without_keys+=("root")
        fi
    fi

    if [[ $CFG_REQUIREMENT_SSHKEY_EASYDOCKER == "true" ]]; then
        if checkSSHSetupKeyPair "$sudo_user_name"; then
            isSuccessful "The SSH Key(s) for $sudo_user_name appears to be set up."
        else
            isNotice "An SSH Key for $sudo_user_name is not found, are you sure you want to disable SSH passwords?"
            users_without_keys+=("$sudo_user_name")
        fi
    fi

    if [[ $CFG_REQUIREMENT_SSHKEY_DOCKERINSTALL == "true" ]]; then
        ### For SSH Key Setup
        if checkSSHSetupKeyPair "$CFG_DOCKER_INSTALL_USER"; then
            isSuccessful "The SSH Key(s) for $CFG_DOCKER_INSTALL_USER appears to be set up."
        else
            isNotice "An SSH Key for $CFG_DOCKER_INSTALL_USER is not found, are you sure you want to disable SSH passwords?"
            users_without_keys+=("$CFG_DOCKER_INSTALL_USER")
        fi
    fi

    # Display the list of users without SSH keys
    if [ ${#users_without_keys[@]} -gt 0 ]; then
        echo ""
        isNotice "SSH Key(s) were missing for the following users:"
        isNotice "Missing Users: ${users_without_keys[@]}"
        echo ""
        while true; do
            isQuestion "Do you want to install (i) the missing SSH keys or (c) continue or (x) to exit? (i/c/x): "
            read -rp "" disable_ssh_passwords
            case "$disable_ssh_passwords" in
                [iI]*)
                    installSSHKeysForDownload install;
                    break
                    ;;
                [cC]*)
                    disableSSHPasswordFunction;
                    break
                    ;;
                [xX]*)
                    break
                    ;;
                *)
                    echo "Please enter 'y' or 'n'."
                    ;;
            esac
        done
    else
        disableSSHPasswordFunction;
    fi
}
