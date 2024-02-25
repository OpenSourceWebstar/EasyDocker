#!/bin/bash

function checkSuccess()
{
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SUCCESS:${NC} $1"
        if [ -f "$logs_dir/$docker_log_file" ]; then
            echo "SUCCESS: $1" | sudo tee -a "$logs_dir/$docker_log_file" >/dev/null
        fi
    else
        echo -e "${RED}ERROR:${NC} $1"
        # Ask to continue
        while true; do
            isQuestion "An error has occurred. Do you want to continue, exit or go to back to the Menu? (c/x/m) "
            read -rp "" error_occurred
            if [[ -n "$error_occurred" ]]; then
                break
            fi
            isNotice "Please provide a valid input."
        done
        
        if [[ "$error_occurred" == [cC] ]]; then
            isNotice "Continuing after error has occured."
        fi
        
        if [[ "$error_occurred" == [xX] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo tee -a "$logs_dir/$docker_log_file"
            exit 1  # Exit the script with a non-zero status to stop the current action
        fi
        
        if [[ "$error_occurred" == [mM] ]]; then
            # Log the error output to the log file
            echo "ERROR: $1" | sudo tee -a "$logs_dir/$docker_log_file"
            echo "===================================" | sudo tee -a "$logs_dir/$docker_log_file"
            resetToMenu
        fi
    fi
}
