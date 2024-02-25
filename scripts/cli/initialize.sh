#!/bin/bash

cliInitialize() 
{
    cliUpdateCommands;

    if [ "$initial_command1" = "help" ] || [ -z "$initial_command1" ]; then
        cliShowCommands;

    elif [ "$initial_command1" = "update" ]; then
        checkUpdates;

    elif [ "$initial_command1" = "reset" ]; then
        runReinstall;

    elif [ "$initial_command1" = "app" ]; then
        # No commands given for app
        if [[ -z "$initial_command2" ]]; then
            cliListAppCommands;

        # First param given
        elif [ "$initial_command2" = "list" ]; then
            databaseListInstalledApps;
        elif [ "$initial_command2" = "start" ]; then
            dockerStartApp "$initial_command3";
        elif [ "$initial_command2" = "stop" ]; then
            dockerStopApp "$initial_command3";
        elif [ "$initial_command2" = "up" ]; then
            dockerComposeUp "$initial_command3";
        elif [ "$initial_command2" = "down" ]; then
            dockerComposeDown "$initial_command3";
        else
            isNotice "Invalid app command used : ${RED}$initial_command3${NC}"
            isNotice "Please use one of the following options below :"
            echo ""
            cliListAppCommands;
        fi

    elif [ "$initial_command1" = "dockertype" ]; then
        # No commands given for app
        if [[ -z "$initial_command2" ]]; then
            cliListDockertypeCommands;

        # First param given
        elif [ "$initial_command2" = "rooted" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=rootless|CFG_DOCKER_INSTALL_TYPE=rooted|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to root in the $configs_dir$config_file_general config."
            source $configs_dir$config_file_general
            dockerSwitcherSwap cli;
        elif [ "$initial_command2" = "rootless" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=rooted|CFG_DOCKER_INSTALL_TYPE=rootless|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to rootless in the $configs_dir$config_file_general config."
            source $configs_dir$config_file_general
            dockerSwitcherSwap cli;
        else
            isNotice "Invalid dockertype used : ${RED}$initial_command2${NC}"
            isNotice "Please use one of the following options below :"
            echo ""
            cliListDockertypeCommands;
        fi

    elif [ -z "$initial_command1" ]; then
        echo ""
        echo "No option given, showing command menu..."
        cliShowCommands

    else
        echo "Unknown command: $initial_command1"
        cliShowCommands
    fi

    echo ""
}
