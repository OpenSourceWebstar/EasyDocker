#!/bin/bash

checkEasyDockerConfigFilesMissingVariables()
{
    # Loop through local config files in $configs_dir
    for local_config_file in "$configs_dir"/*; do
        if [ -f "$local_config_file" ]; then
            local local_config_filename=$(basename "$local_config_file")

            # Extract config variables from the local file
            local local_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$local_config_file" | sed 's/=$//'))

            # Find the corresponding .config file in $install_configs_dir
            local remote_config_file="$install_configs_dir$local_config_filename"

            if [ -f "$remote_config_file" ]; then
                # Extract config variables from the remote file
                local remote_variables=($(grep -o 'CFG_[A-Za-z0-9_]*=' "$remote_config_file" | sed 's/=$//'))

                # Filter out empty variable names from the remote variables
                local remote_variables=("${remote_variables[@]//[[:space:]]/}")  # Remove whitespace
                local remote_variables=($(echo "${remote_variables[@]}" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' '))

                # Compare local and remote variables
                for remote_var in "${remote_variables[@]}"; do
                    if ! [[ " ${local_variables[@]} " =~ " $remote_var " ]]; then
                        var_line=$(grep "${remote_var}=" "$remote_config_file")

                        echo ""
                        echo "####################################################"
                        echo "###   Missing EasyDocker Config Variable Found   ###"
                        echo "####################################################"
                        echo ""
                        isNotice "Variable '$remote_var' is missing in the local config file '$local_config_filename'."
                        echo ""
                        isOption "1. Add the '$var_line' to the '$local_config_filename'"
                        isOption "2. Add the '$remote_var' with my own value"
                        isOption "x. Skip"
                        echo ""

                        isQuestion "Enter your choice (1 or 2) or 'x' to skip : "
                        read -rp "" choice

                        case "$choice" in
                            1)
                                echo ""
                                # Check if the file ends with an empty line
                                if fileHasEmptyLine "$local_config_file"; then
                                    echo "$var_line" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                else
                                    echo "" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                    echo "$var_line" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                fi

                                checkSuccess "Adding the $var_line to '$local_config_filename':"
                                source "$local_config_file"
                            ;;
                            2)
                                echo ""
                                isQuestion "Enter your value for $remote_var: "
                                read -p " " custom_value
                                echo ""

                                if fileHasEmptyLine "$local_config_file"; then
                                    echo "${remote_var}=$custom_value" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                else
                                    echo "" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                    echo "${remote_var}=$custom_value" | sudo tee -a "$local_config_file" > /dev/null 2>&1
                                fi

                                checkSuccess "Adding the ${remote_var}=$custom_value to '$local_config_filename':"
                                source "$local_config_file"
                            ;;
                            [xX])
                                # User chose to skip
                            ;;
                            *)
                                isNotice "Invalid choice. Skipping."
                            ;;
                        esac
                    fi
                done
            #else
                #echo "Debug: Remote config file not found: $remote_config_file"
            fi
        fi
    done

    isSuccessful "EasyDocker Config variable check completed."  # Indicate completion
}
