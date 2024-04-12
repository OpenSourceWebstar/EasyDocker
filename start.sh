#!/bin/bash

initial_command1="$1"
initial_command2="$2"
initial_command3="$3"
initial_command4="$4"
initial_command5="$5"

# Used for saving directory path
initial_path="$6"
initial_path_save=$initial_path

displayEasyDockerLogo() 
{
    echo "
____ ____ ____ _   _    ___  ____ ____ _  _ ____ ____ 
|___ |__| [__   \_/     |  \ |  | |    |_/  |___ |__/ 
|___ |  | ___]   |      |__/ |__| |___ | \_ |___ |  \ "
    echo ""
}

initEasyDocker()
{
    # For the full application loading
    if [[ "$initial_command1" == "run" ]]; then
        init_run_flag="true"
        displayEasyDockerLogo;
        source "scripts/source/load_sources.sh"
	else
    # For the CLI loading
        init_run_flag="false"
        displayEasyDockerLogo;
        source "scripts/source/load_sources.sh"
    fi
}

initEasyDocker;