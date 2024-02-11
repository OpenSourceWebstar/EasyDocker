#!/bin/bash

cliListCommands() 
{
    if [ "$initial_command1" == "help" ] || [ -z "$initial_command1" ]; then
        cliShowCommands;
    elif [ "$initial_command1" == "application" ]; then
        if [[ "$initial_command2" == "" ]] && [[ "$initial_command3" == "" ]]; then
            cliListApplicationCommands;
        elif [[ "$initial_command2" != "" ]] && [[ "$initial_command3" == "" ]]; then
            cliApplicationRunCommands $initial_command2 $initial_command3;
        fi
    elif [ "$initial_command1" == "dockertype" ]; then
        cliListDockertypeCommands;
    else
        echo "Unknown command: $1"
        cliShowCommands;
    fi
}

cliShowCommands() 
{
    echo "Available Commands:"
    echo ""
    echo "  easydocker start                        - Start the EasyDocker control panel"
    echo "  easydocker application [name] [action]  - Manage applications in EasyDocker"
    echo "  easydocker dockertype [type]            - Set the Docker type"
}

cliListApplicationCommands() 
{
    echo "Available Application Commands:"
    echo ""
    echo "  easydocker application list - List all installed applications"
    echo ""
    echo "  easydocker application install [name]  - Install the specified application"
    echo "  easydocker application start [name]    - Start the specified application (Must be installed)"
    echo "  easydocker application stop [name]     - Stop the specified application (Must be installed)"
    echo "  easydocker application up [name]       - Docker-Compose up (Rebuild application)"
    echo "  easydocker application down [name]     - Docker-Compose up (Uninstall application)"
}

cliApplicationRunCommands()
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
                echo "No application name supplied"
            fi
            ;;
        *)
            echo "Invalid command"
            ;;
    esac
}

cliListDockertypeCommands() 
{
    echo "Available Dockertype Commands:"
    echo ""
    echo "  easydocker dockertype root     - Set Docker to use root privileges"
    echo "  easydocker dockertype rootless - Set Docker to run in rootless mode"
}


cliApplicationRunCommands()
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
