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
    cliUpdateCommands;

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
        elif [ "$initial_command2" = "start" ]; then
            dockerStartApp "$initial_command3";
        elif [ "$initial_command2" = "stop" ]; then
            dockerStopApp "$initial_command3";
        elif [ "$initial_command2" = "up" ]; then
            dockerAppUp "$initial_command3";
        elif [ "$initial_command2" = "down" ]; then
            dockerAppDown "$initial_command3";
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
            dockerSwitchBetweenRootAndRootless cli;
        elif [ "$initial_command2" = "rootless" ]; then
            result=$(sudo sed -i "s|CFG_DOCKER_INSTALL_TYPE=rooted|CFG_DOCKER_INSTALL_TYPE=rootless|" "$configs_dir$config_file_general")
            checkSuccess "Updating CFG_DOCKER_INSTALL_TYPE to rootless in the $configs_dir$config_file_general config."
            source $configs_dir$config_file_general
            dockerSwitchBetweenRootAndRootless cli;
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
    echo "  easydocker app install [name]          - Install the specified app"
    echo "  easydocker app start [name]            - Start the specified app (Must be installed)"
    echo "  easydocker app stop [name]             - Stop the specified app (Must be installed)"
    echo "  easydocker app up [name]               - Docker-Compose up (Rebuild app)"
    echo "  easydocker app down [name]             - Docker-Compose up (Uninstall app)"
    echo ""
}

cliListDockertypeCommands() 
{
    # Select preexisting docker_type
    if [ -f "$docker_dir/$db_file" ]; then
        local docker_type_cli=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "docker_type";')
        # Insert into DB if something doesnt exist
        if [[ $docker_type_cli == "" ]]; then
            databaseOptionInsert "docker_type" $CFG_DOCKER_INSTALL_TYPE;
            local docker_type_cli=$(sudo sqlite3 "$docker_dir/$db_file" 'SELECT content FROM options WHERE option = "docker_type";')
        fi
    fi
    echo ""
    isNotice "The current Docker Setup Type is currently : ${RED}$docker_type_cli${NC}" 
    echo ""
    echo "Available Dockertype Commands:"
    echo ""
    echo "  easydocker dockertype rooted          - Set Docker to use rooted privileges"
    echo "  easydocker dockertype rootless        - Set Docker to run in rootless mode"
    echo ""
}
