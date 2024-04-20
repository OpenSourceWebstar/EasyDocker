#!/bin/bash

createSuccessfulRunFile() 
{
    sudo echo "EasyDocker last ran on :" $(date) > $docker_dir/run.txt
}