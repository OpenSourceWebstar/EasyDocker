#!/bin/bash

installCrontab()
{
    if [[ "$CFG_REQUIREMENT_CRONTAB" == "true" ]]; then
        if [[ "$CRONTAB_SETUP" == "false" ]]; then
            echo ""
            echo "############################################"
            echo "######       Crontab Install          ######"
            echo "############################################"
            echo ""

            # Check to see if already installed
            ISCRON=$( (sudo -u $sudo_user_name crontab -l) 2>&1 )
            if [[ "$ISCRON" == *"command not found"* ]]; then
                isNotice "Crontab is not installed, setting up now."
                local result=$(sudo apt update)
                checkSuccess "Updating apt for post installation"
                local result=$(sudo apt install cron -y)
                isSuccessful "Installing crontab application"
                local result=$(sudo -u $sudo_user_name crontab -l)
                isSuccessful "Enabling crontab on the system"
            fi

            search_line="# cron is set up for $sudo_user_name"
            cron_output=$(sudo -u $sudo_user_name crontab -l 2>/dev/null)

            if [[ ! $cron_output == *"$search_line"* ]]; then
                local result=$( (sudo -u $sudo_user_name crontab -l 2>/dev/null; echo "# cron is set up for $sudo_user_name") | sudo -u $sudo_user_name crontab - 2>/dev/null )
                checkSuccess "Setting up crontab for $sudo_user_name user"
            fi

            export VISUAL=$CFG_TEXT_EDITOR
            export EDITOR=$CFG_TEXT_EDITOR

            isSuccessful "Crontab has been setup on the system"
            #installCrontabSSHScan;
        fi
    fi
}
