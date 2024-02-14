#!/bin/bash

cliUpdateCommands() 
{
    if [[ "$initial_command1" == "empty" ]]; then 
        initial_command1=""
    fi
    
    if [[ "$initial_command2" == "empty" ]]; then 
        initial_command2=""
    fi
    
    if [[ "$initial_command3" == "empty" ]]; then 
        initial_command3=""
    fi
    
    if [[ "$initial_command4" == "empty" ]]; then 
        initial_command4=""
    fi
    
    if [[ "$initial_command5" == "empty" ]]; then 
        initial_command5=""
    fi

    #echo "initial_command1 $initial_command1"
    #echo "initial_command2 $initial_command2"
    #echo "initial_command3 $initial_command3"
    #echo "initial_command4 $initial_command4"
    #echo "initial_command5 $initial_command5"
}

cliInitialize() 
{
    cliUpdateCommands

    if [ "$initial_command1" = "help" ] || [ -z "$initial_command1" ]; then
        cliShowCommands;

    elif [ "$initial_command1" = "update" ]; then
        checkUpdates;

    elif [ "$initial_command1" = "reset" ]; then
        runInitReinstall;

    elif [ "$initial_command1" = "app" ]; then
        # No commands given for app
        if [[ -z "$initial_command2" ]]; then
            cliListAppCommands;

        # First param given
        elif [ "$initial_command2" = "list" ]; then
            databaseListInstalledApps;
            echo ""
        elif [ "$initial_command2" = "start" ]; then
            dockerStartApp "$initial_command3";
        elif [ "$initial_command2" = "stop" ]; then
            dockerStopApp "$initial_command3";
        elif [ "$initial_command2" = "up" ]; then
            dockerAppUp "$initial_command3";
        elif [ "$initial_command2" = "down" ]; then
            dockerAppDown "$initial_command3";
        fi

    elif [ "$initial_command1" = "dockertype" ]; then
        # No commands given for app
        if [[ -z "$initial_command2" ]]; then
            cliListDockertypeCommands;

        # First param given
        elif [ "$initial_command2" = "root" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=rootless|CFG_DOCKER_INSTALL_TYPE=root|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to root in the $configs_dir$config_file_general config."
            dockerSwitchBetweenRootAndRootless cli;
        elif [ "$initial_command2" = "rootless" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=root|CFG_DOCKER_INSTALL_TYPE=rootless|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to rootless in the $configs_dir$config_file_general config."
            dockerSwitchBetweenRootAndRootless cli;
        fi

    elif [ -z "$initial_command1" ]; then
        echo ""
        echo "No option given, showing command menu..."
        cliShowCommands

    else
        echo "Unknown command: $initial_command1"
        cliShowCommands
    fi
}

cliShowCommands() 
{
    echo ""
    echo "Available Commands:"
    echo ""
    echo "  easydocker run                          - Run the EasyDocker control panel"
    echo "  easydocker update                       - Updates EasyDocker to the latest version"
    echo "  easydocker reset                        - Reinstall EasyDocker install files"
    echo "  easydocker app [name] [action]          - Manage apps in EasyDocker"
    echo "  easydocker dockertype [type]            - Set the Docker type"
    echo ""
}

cliListAppCommands() 
{
    echo ""
    echo "Available App Commands:"
    echo ""
    echo "  easydocker app list - List all installed apps"
    echo ""
    echo "  easydocker app install [name]  - Install the specified app"
    echo "  easydocker app start [name]    - Start the specified app (Must be installed)"
    echo "  easydocker app stop [name]     - Stop the specified app (Must be installed)"
    echo "  easydocker app up [name]       - Docker-Compose up (Rebuild app)"
    echo "  easydocker app down [name]     - Docker-Compose up (Uninstall app)"
    echo ""
}

cliListDockertypeCommands() 
{
    echo ""
    echo "Available Dockertype Commands:"
    echo ""
    echo "  easydocker dockertype root     - Set Docker to use root privileges"
    echo "  easydocker dockertype rootless - Set Docker to run in rootless mode"
    echo ""
}
