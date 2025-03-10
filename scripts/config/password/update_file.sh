#!/bin/bash

scanFileForRandomPassword() {
    local file="$1"
    local passwords=()

    if [ -f "$file" ]; then
        for i in {1..9}; do
            local placeholder="RANDOMIZEDPASSWORD${i}"

            if sudo grep -q "$placeholder" "$file"; then
                if sudo grep -q "${placeholder}[[:space:]]*--bcrypt" "$file"; then
                    passwords[$i]=$(generateRandomPassword | hashPassword)
                    sudo sed -i -E "s/${placeholder}[[:space:]]*--bcrypt/\"$(echo "${passwords[$i]}" | sed 's/["]/\\"/g')\"/g" "$file"
                    isSuccessful "Updated ${placeholder} with Bcrypt and removed marker in $(basename "$file")."
                else
                    if [ -z "${passwords[$i]}" ]; then
                        passwords[$i]=$(generateRandomPassword)
                    fi
                    sudo sed -i -E "s/${placeholder}/\"${passwords[$i]}\"/g" "$file"
                    isSuccessful "Updated ${placeholder} in $(basename "$file") with a new password."
                fi
            fi
        done

        local placeholder="RANDOMIZEDPASSWORD"
        if sudo grep -q "$placeholder" "$file"; then
            if sudo grep -q "${placeholder}[[:space:]]*--bcrypt" "$file"; then
                local random_password=$(generateRandomPassword | hashPassword)
                sudo sed -i -E "s/${placeholder}[[:space:]]*--bcrypt/\"$(echo "${random_password}" | sed 's/["]/\\"/g')\"/g" "$file"
                isSuccessful "Updated ${placeholder} with Bcrypt and removed marker in $(basename "$file")."
            else
                local random_password=$(generateRandomPassword)
                sudo sed -i -E "s/${placeholder}/\"${random_password}\"/g" "$file"
                isSuccessful "Updated ${placeholder} in $(basename "$file") with a new password."
            fi
        fi
    fi
}
