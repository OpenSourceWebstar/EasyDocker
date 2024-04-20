#!/bin/bash

checkSuccessfulRun() 
{
    local flag="$1"

    if [ -f "$docker_dir/$run_file" ]; then
        isSuccessful "EasyDocker setup run file found."
    else
        isError "EasyDocker setup run file not found..."
        isNotice "Please use the 'easydocker run' or 'easydocker install' command"
        exit
    fi
}