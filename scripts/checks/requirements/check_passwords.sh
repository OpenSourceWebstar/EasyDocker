#!/bin/bash

checkPasswordsRequirement() 
{
    if [[ $CFG_REQUIREMENT_PASSWORDS == "true" ]]; then
        ### Password randomizer
        pass_found=0

        for config_file in "$configs_dir"/*; do
            if [ -f "$config_file" ] && grep -q "RANDOMIZEDPASSWORD" "$config_file"; then
                pass_found=1
            fi
        done

        if [ "$pass_found" -eq 1 ]; then
            isSuccessful "Passwords found to randomize in config files."
            ((preinstallneeded++))
        else
            isSuccessful "No passwords found to change."
        fi
    fi
}
