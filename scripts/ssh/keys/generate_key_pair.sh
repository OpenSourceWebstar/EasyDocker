#!/bin/bash

generateSSHKeyPair()
{
    local username="$1"
    local private_key_path="$2"
    local private_key_full="$3"
    local public_key_full="$4"
    local flag="$5"

    echo ""
    echo ""
    echo "############################################"
    echo "######   SSH Key Generation for $username"
    echo "############################################"
    echo ""

    if [[ "$flag" == "reinstall" ]]; then
        if [ -f "$private_key_full" ]; then
            result=$(sudo rm $private_key_full)
            checkSuccess "Deleted old private SSH key $(basename "$private_key_full")"
        fi
        if [ -f "$public_key_full" ]; then
            result=$(sudo rm $public_key_full)
            checkSuccess "Deleted old public SSH key $(basename "$public_key_full")"
        fi
    fi

    if [[ "$username" == "root" ]]; then
        local ssh_passphrase=$CFG_SSHKEY_PASSPHRASE_ROOT
    elif [[ "$username" == "$sudo_user_name" ]]; then
        local ssh_passphrase=$CFG_SSHKEY_PASSPHRASE_ROOT
    elif [[ "$username" == "$CFG_DOCKER_INSTALL_USER" ]]; then
        local ssh_passphrase=$CFG_SSHKEY_PASSPHRASE_DOCKERINSTALL
    fi

    # Supply $CFG_DOCKER_INSTALL_USER password for sudo usage
    if [[ "$username" == "$CFG_DOCKER_INSTALL_USER" ]]; then
        result=$(echo -e "$CFG_DOCKER_INSTALL_PASS\n$ssh_passphrase\n$ssh_passphrase" | sudo -u $username ssh-keygen -t ed25519 -f "$ssh_dir/$(basename "$private_key_full")" -C "$CFG_EMAIL" -N "" && sudo -u $username cat "$ssh_dir/$(basename "$private_key_full").pub" | sudo -u $username tee -a "$ssh_dir/$(basename "$private_key_full")" > /dev/null)
        checkSuccess "New ED25519 key pair generated for $username"
    else
        result=$(echo -e "$ssh_passphrase\n$ssh_passphrase" | sudo -u $username sudo ssh-keygen -t ed25519 -f "$ssh_dir/$(basename "$private_key_full")" -C "$CFG_EMAIL" -N "" && sudo -u $username cat "$ssh_dir/$(basename "$private_key_full").pub" | sudo tee -a "$ssh_dir/$(basename "$private_key_full")" > /dev/null)
        checkSuccess "New ED25519 key pair generated for $username"
    fi

    if [ -f "$ssh_dir/$(basename $private_key_full)" ]; then
        updateFileOwnership $ssh_dir/$(basename $private_key_full) $username $username
        result=$(sudo mv "$ssh_dir/$(basename "$private_key_full")" "$private_key_full")
        checkSuccess "Private key moved to $private_key_full"
    fi

    if [ -f "$ssh_dir/$(basename $public_key_full)" ]; then
        updateFileOwnership $ssh_dir/$(basename $public_key_full) $username $username
        result=$(sudo mv "$ssh_dir/$(basename "$public_key_full")" "$public_key_full")
        checkSuccess "Public key moved to $public_key_full"
    fi

    result=$(createTouch "$ssh_dir/public/$(basename $private_key_full)" $username)
    checkSuccess "Creating the passphrase txt to private folder."

    result=$(echo "$ssh_passphrase" | sudo tee -a "$ssh_dir/public/$(basename $private_key_full)" > /dev/null)
    checkSuccess "Adding the ssh_passphrase to the $(basename "$private_key_full").txt file."

    result=$(sudo chmod 644 $ssh_dir/private/$(basename $private_key_full))
    checkSuccess "Updating permissions for $(basename $private_key_full)"

    setupSSHAuthorizedKeys $username $public_key_full;

    updateSSHHTMLSSHKeyLinks;

    # Select preexisting docker_type
    if [ -f "$docker_dir/$db_file" ]; then
        local ssh_new_key=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "ssh_new_key";')
        # Insert into DB if something doesnt exist
        if [[ $docker_type == "" ]]; then
            databaseOptionInsert "ssh_new_key" "true";
            local ssh_new_key=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "ssh_new_key";')
        fi
    else
        return;
    fi

}
