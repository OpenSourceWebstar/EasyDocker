#!/bin/bash

checkIpsHostnameFilesMissingEntries() 
{

	if [[ $CFG_REQUIREMENT_MISSING_IPS == "true" ]]; then
        local ips_file="$configs_dir$ip_file"

        if [ -f "$ips_file" ]; then
            local remote_ips_file="$install_configs_dir$ip_file"

            if [ -f "$remote_ips_file" ]; then
                # Compare the local and remote files and find missing lines
                local missing_lines=$(sudo diff --new-line-format="%L" --old-line-format="" --unchanged-line-format="" "$ips_file" "$remote_ips_file")

                local IFS=$'\n' # Set the internal field separator to newline
                for ips_line in $missing_lines; do
                    echo ""
                    echo "####################################################"
                    echo "###        Missing IP/Hostname Entry Found       ###"
                    echo "####################################################"
                    echo ""
                    isNotice "Entry is missing in the config file '$ips_file':"
                    echo ""
                    
                    while true; do
                        isOption "1. Add $ips_line to the '$ips_file'"
                        isOption "x. Skip"
                        
                        echo ""
                        isQuestion "Enter your choice (1 or x): "
                        read -rp "" ipschoice
                        echo ""
                        case "$ipschoice" in
                            1)
                                echo "$ips_line" | sudo tee -a "$ips_file" > /dev/null 2>&1
                                checkSuccess "Adding the missing entry to $ips_file"
                                break
                                ;;
                            x)
                                # User chose to skip
                                isNotice "Skipping."
                                break
                                ;;
                            *)
                                isNotice "Invalid choice. Please enter '1' or 'x'."
                                ;;
                        esac
                    done
                done
            fi

            local IFS=" " # Reset the internal field separator
        fi

        isSuccessful "IP/Hostname record check completed."  # Indicate completion
    fi
}
