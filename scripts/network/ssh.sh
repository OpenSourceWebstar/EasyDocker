#!/bin/bash

sshRemote() 
{
    local ssh_pass="$1"
    local ssh_port="$2"
    local ssh_login="$3"
    local ssh_command="$4"

    # Run the SSH command using the existing SSH variables
    sudo sshpass -p "$ssh_pass" sudo ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $ssh_port $ssh_login $ssh_command
    #checkSuccess "Running Remote SSH Command : $ssh_command"
}