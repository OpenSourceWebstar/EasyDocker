#!/bin/bash

installSwapfile()
{
    if [[ "$CFG_REQUIREMENT_SWAPFILE" == "true" ]]; then
        if [ ! -f "$swap_file" ]; then
            echo ""
            echo "############################################"
            echo "######       Increasing Swapfile      ######"
            echo "############################################"
            echo ""
            ISSWAP=$( (sudo -u $sudo_user_name swapoff /swapfile) 2>&1 )
            if [[ "$ISSWAP" != *"No such file or directory"* ]]; then
                local result=$(sudo -u $sudo_user_name swapoff /swapfile)
                isSuccessful "Turning off /swapfile (if needed)"
            fi

            local result=$(sudo -u $sudo_user_name fallocate -l $CFG_SWAPFILE_SIZE /swapfile)
            checkSuccess "Allocating $CFG_SWAPFILE_SIZE to the /swapfile"
            
            local result=$(sudo chmod 0600 /swapfile)
            checkSuccess "Adding permissions to the /swapfile"

            local result=$(sudo -u $sudo_user_name mkswap /swapfile)
            checkSuccess "Swapping to the new /swapfile"

            local result=$(sudo -u $sudo_user_name swapon /swapfile)
            checkSuccess "Enabling the new /swapfile"
        fi
    fi
}
