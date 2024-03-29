#!/bin/bash

checkConfigFirstInstall()
{
    # Flag to control the loop
    local config_check_done=false
    
    while ! "$config_check_done"; do
        # Check if configs have not been changed (Install name, email, domain)
        if sudo grep -q "Change-Me" "$configs_dir/$config_file_general" && sudo grep -q "change@me.com" "$configs_dir/$config_file_general" && sudo grep -q "changeme.co.uk" "$configs_dir/$config_file_general"; then
            echo ""
            echo "####################################################"
            echo "###            First Time Installation           ###"
            echo "####################################################"
            echo ""
            isNotice "In order for the installation to proceed, you need to setup the following"
            isNotice "---- Install Name, Email & Domain (Timezone is optional but suggested!)"
            echo ""
            isNotice "The simple setup will guide you through the above, and advanced gives you will full control of all"
            echo ""
            isOption "Type the option (s) - For the simple, quick setup."
            isOption "Type the option (a) - For the advanced manual config setup."
            echo ""
            isNotice "You can always edit the config manually at any time after the initial setup"
            echo ""
            while true; do
                isQuestion "Which setup would you like to choose? (s/a): "
                read -rp "" configsnotchanged
                echo ""
                case $configsnotchanged in
                    [sS])
                        isSuccessful "The simple setup option has been selected."
                        echo ""
                        local general_config_file="$configs_dir$config_file_general"
                        # Install Name
                        while true; do
                            isQuestion "Please input a unique Install Name - e.g (Jake-VPS-1) : "
                            read -p "" setup_install_name
                            # Check if the input contains only characters, numbers, and hyphens
                            if [[ "$setup_install_name" =~ ^[a-zA-Z0-9-]+$ ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input (only characters, numbers, and hyphens allowed)."
                        done
                        result=$(sudo sed -i "s|CFG_INSTALL_NAME=Change-Me|CFG_INSTALL_NAME=$setup_install_name|" "$general_config_file")
                        checkSuccess "Updating CFG_INSTALL_NAME to $setup_install_name in the $config_file_general config."

                        # Email address
                        while true; do
                            isQuestion "Please input an email address (Used for LetsEncrypt Certificates) : "
                            read -p "" setup_email
                            emailValidation "$setup_email"
                            if [[ $? -eq 0 ]]; then
                                break
                            fi
                            isNotice "Please provide a valid email address."
                        done
                        result=$(sudo sed -i "s|CFG_EMAIL=change@me.com|CFG_EMAIL=$setup_email|" "$general_config_file")
                        checkSuccess "Updating CFG_EMAIL to $setup_email in the $config_file_general config."

                        # Domain Name
                        while true; do
                            isQuestion "Are you wanting to use public SSL LetsEncrypt Certified applications? (y/n): "
                            read -p "" setup_certificate_letsencrypt
                            # Check if the input is a valid domain name using regex
                            if [[ "$setup_certificate_letsencrypt" != [yYnN] ]]; then
                                break
                            fi
                            isNotice "Please provide a valid input."
                        done

                        if [[ "$setup_certificate_letsencrypt" == [yY] ]]; then
                            # Domain Name
                            while true; do
                                isQuestion "Please input a domain that is pointed towards this server - e.g (example.org) : "
                                read -p "" setup_domain_name
                                # Check if the input is a valid domain name using regex
                                if [[ "$setup_domain_name" =~ ^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$ ]]; then
                                    break
                                fi
                                isNotice "Please provide a valid domain name."
                            done
                            result=$(sudo sed -i "s|CFG_DOMAIN_1=changeme.co.uk|CFG_DOMAIN_1=$setup_domain_name|" "$general_config_file")
                            checkSuccess "Updating CFG_DOMAIN_1 to $setup_domain_name in the $config_file_general config."
                        fi

                        # Timezones
                        while true; do
                            # Create a list of commonly used timezones
                            local common_timezones=("America/New_York" "America/Chicago" "America/Los_Angeles" "Europe/London" "Europe/Paris" "Asia/Tokyo" "Australia/Sydney")

                            # Get a list of all available timezones
                            local all_timezones=$(sudo timedatectl list-timezones)

                            # Merge the common timezones with all timezones and remove duplicates
                            local timezones=($(echo "${common_timezones[@]}" "${all_timezones[@]}" | tr ' ' '\n' | sort -u))

                            # Create a temporary file to store the menu choices
                            local tempfile=$(sudo mktemp /tmp/timezone_menu.XXXXXX) || exit 1

                            # Populate the tempfile with timezone options
                            for tz in "${timezones[@]}"; do
                                echo "$tz" | sudo tee -a "$tempfile" > /dev/null
                            done

                            # Show the menu using dialog
                            LC_COLLATE=C sudo dialog --menu "Select a timezone:" 20 60 15 $(cat "$tempfile") 2> "$tempfile"

                            # Get the selected timezone from the tempfile
                            local setup_timezone=$(sudo cat "$tempfile")

                            # Cleanup the temporary file
                            sudo rm -f "$tempfile"

                            # Break the loop if a timezone is selected
                            if [ -n "$setup_timezone" ]; then
                                isSuccessful "You selected: $setup_timezone"
                                break
                            else
                                isNotice "No timezone selected. Please try again."
                            fi
                        done

                        result=$(sudo sed -i "s|CFG_TIMEZONE=Etc/UTC|CFG_TIMEZONE=$setup_timezone|" "$general_config_file")
                        checkSuccess "Updating CFG_TIMEZONE to $setup_timezone in the $config_file_general config."
                        
                        sourceScanFiles "easydocker_configs";

                        config_check_done=true  # Set the flag to exit the loop
                        break  # Exit the loop
                    ;;
                    [aA])
                        viewEasyDockerConfigs;
                        # No need to set config_check_done here; it will continue to the next iteration of the loop
                        break  # Exit the loop
                    ;;
                    *)
                        isNotice "Please provide a valid input (s or a)."
                    ;;
                esac
            done
        else
            isSuccessful "Config file has been setup, continuing..."
            local config_check_done=true  # Set the flag to exit the loop
        fi
    done
}
