#!/bin/bash

# Function to clean all crontab
crontabClean() 
{
    data_to_remove=" >> /docker/logs/backup.log 2>&1"
    
    # Check if the string exists in the crontab
    if crontab -l | grep -q "$data_to_remove"; then
        # If found, remove occurrences of the string from the crontab
        crontab -l | sed "s|$data_to_remove||g" | crontab -
        isSuccessful "Removed old data from crontab entries."
    fi
}