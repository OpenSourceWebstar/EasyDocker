#!/bin/bash

cliInitilize() 
{
    if [ "$initial_command1" == "help" ] || [ -z "$initial_command1" ]; then
        cliShowCommands;
    # This is handled in the initEasyDocker function
    #elif [ "$initial_command1" == "run" ]; then
    elif [ "$initial_command1" == "update" ]; then
        checkUpdates cli;
    elif [ "$initial_command1" == "reset" ]; then
        runInitReinstall;
    elif [ "$initial_command1" == "app" ]; then
        if [[ "$initial_command2" == "" ]] && [[ "$initial_command3" == "" ]]; then
            cliListAppCommands;
        elif [[ "$initial_command2" != "" ]] && [[ "$initial_command3" == "" ]]; then
            cliAppRunCommands $initial_command2 $initial_command3;
        fi
    elif [ "$initial_command1" == "dockertype" ]; then
        cliListDockertypeCommands;
    elif [ "$initial_command1" == "empty" ]; then
        echo ""
        echo "No option given, showing command menu..."
        cliShowCommands;
    elif [ "$initial_command1" == "" ]; then
        echo ""
        echo "No option given, showing command menu..."
        cliShowCommands;
    else
        echo "Unknown command: $initial_command1"
        cliShowCommands;
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

cliAppRunCommands()
{
    local param1="$1"
    local param2="$2"

    # Database Check
    if [ -f "$docker_dir/$db_file" ] ; then
        echo "EasyDocker has not been setup, please run the easydocker start command first."
        return
    fi

    case "$param1" in
        list)
            databaseListInstalledApps;
            ;;
        start | stop | up | down)
            if [ -n "$param2" ]; then
                case "$param1" in
                    start) dockerStartApp "$param2" ;;
                    stop) dockerStopApp "$param2" ;;
                    up) dockerAppUp "$param2" ;;
                    down) dockerAppDown "$param2" ;;
                esac
            else
                echo "No app name supplied"
            fi
            ;;
        *)
            echo "Invalid command"
            ;;
    esac
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


cliAppRunCommands()
{
    local param1="$1"
    local param2="$2"

    # Database Check
    if [ -f "$docker_dir/$db_file" ] ; then
        echo "EasyDocker has not been setup, please run the easydocker start command first."
        return
    fi

    case "$param1" in
        root)
            dockerSwitchBetweenRootAndRootless;
            ;;
        rootless)
            databaseListInstalledApps;
            ;;

        *)
            echo "Invalid command"
            ;;
    esac
}
