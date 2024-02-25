#!/bin/bash

runReinstall() 
{
    echo ""
    echo "####################################################"
    echo "###           Reinstalling EasyDocker            ###"
    echo "####################################################"
    echo ""
    sudo bash -c 'rm -rf /docker/install/ && cd ~ && rm -rf init.sh && apt-get install wget -y && wget -O init.sh https://raw.githubusercontent.com/OpenSourceWebstar/EasyDocker/main/init.sh && chmod 0755 init.sh && ./init.sh run'
    exit 0  # Exit the entire script
}