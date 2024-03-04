#!/bin/bash

installDockerRootedCheck()
{
    ##########################################
    #### Test if Docker Service is Running ###
    ##########################################
    if [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
        ISACT=$( (sudo systemctl is-active docker ) 2>&1 )
        if [[ "$ISACT" != "active" ]]; then
            isNotice "Checking Docker service status. Waiting if not found."
            while [[ "$ISACT" != "active" ]] && [[ $X -le 10 ]]; do
                sudo systemctl start docker | sudo tee -a "$logs_dir/$docker_log_file" 2>&1
                sleep 10s &
                pid=$! # Process Id of the previous running command
                spin='-\|/'
                i=0
                while kill -0 $pid 2>/dev/null
                do
                    i=$(( (i+1) %4 ))
                    printf "\r${spin:$i:1}"
                    sleep .1
                done
                printf "\r"
                ISACT=`sudo systemctl is-active docker`
                let X=X+1
                echo "$X"
            done
        fi
    fi
}
