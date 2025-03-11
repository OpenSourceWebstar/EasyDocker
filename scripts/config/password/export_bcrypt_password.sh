#!/bin/bash

exportBcryptPassword() 
{
	if [[ $CFG_REQUIREMENT_BCRYPT_SAVE == "true" ]]; then
        local app_name="$1"
        local placeholder="$2"
        local raw_password="$3"
        local log_file="$containers_dir/bcrypt.txt"

        if [ ! -f "$log_file" ]; then
            local result=$(sudo touch "$log_file")
            checkSuccess "Created bcrypt.txt file."

            local result=$(sudo chmod 600 "$log_file") 
            checkSuccess "Adjust bcrypt.txt file permissions"
        fi

        local result=$(sudo sed -i "/^$app_name $placeholder /d" "$log_file")
        checkSuccess "Remove existing entry for the same app & placeholder"

        local result=$(echo "$app_name $placeholder $raw_password" | sudo tee -a "$log_file" > /dev/null)
        checkSuccess "Log unencrypted password before hashing"
    fi
}