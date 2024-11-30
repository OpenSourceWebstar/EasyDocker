#!/bin/bash

# Function to clean all crontab
crontabClean() 
{
    # Check if the string exists in the crontab
    if crontab -l | grep -q " >> /docker/logs/backup.log 2>&1"; then
        # If found, remove occurrences of the string from the crontab
        crontab -l | sed "s/ >> /docker/logs/backup.log 2>&1//g" | crontab -
        isSuccessful "Removed old data from crontab entries."
    fi
}