#!/bin/bash

# Function to remove all crontab data
crontabClear() 
{
    echo "" | sudo -u $sudo_user_name crontab -
    echo "All crontab data has been deleted."
}