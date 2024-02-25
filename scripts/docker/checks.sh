#!/bin/bash

dockerCheckContainerHealth() 
{
    local container_name="$1"
    local health_status=$(dockerCommandRun "docker inspect --format='{{json .State.Health.Status}}' $container_name")

    if [ "$health_status" == "\"healthy\"" ]; then
        return 0  # Container is healthy
    else
        return 1  # Container is not healthy
    fi
}

dockerCheckContainerHealthLoop() 
{
    local container_name="$1"
    local timeout="$2"
    local wait_time="$3"

    isNotice "This container health check will timeout after $timeout seconds"

    local counter=0
    while true; do
        if dockerCheckContainerHealth "$container_name"; then
            isSuccessful "Container is healthy!"
            break
        fi

        if [ "$counter" -ge "$timeout" ]; then
            isNotice "Container health check timed out after $timeout seconds. Exiting..."
            break
        fi

        isNotice "Waiting $wait_time seconds for container to turn healthy..."
        sleep "$wait_time"
        counter=$((counter + wait_time))
    done
}

dockerCheckIsRunningForUser() 
{
    local type="$1"

    # Check if Docker is running for the specified user
    if [[ $type == "rootless" ]]; then
        local docker_command='docker ps 2>&1'
        local result=$(dockerCommandRunInstallUser "$docker_command")
    elif [[ $type == "rooted" ]]; then
        local docker_command='sudo docker ps 2>&1'
        local result=$(eval "$docker_command")
    else
        echo "Invalid user type specified."
        return 1
    fi

    # Check the result
    if [[ $result =~ "Cannot connect to the Docker daemon" ]]; then
        #echo "Docker is not running for the specified user."
        return 1  # Docker is not running
    else
        #echo "Docker is running for the specified user."
        return 0  # Docker is running
    fi
}

dockerCheckAllowedInstall() 
{
    local app_name="$1"

    #if [ "$status" == "installed" ]; then
    #elif [ "$status" == "running" ]; then
    #elif [ "$status" == "not_installed" ]; then
    #elif [ "$status" == "invalid_flag" ]; then

    case "$app_name" in
        "wireguard")
            # Check if WireGuard is already installed and load params
            if [[ -e /etc/wireguard/params ]]; then
                isError "Virtualmin is installed, this will conflict with $app_name."
                isError "Installation is now aborting..."
                dockerUninstallApp "$app_name"
                return 1
            fi
            ;;
        #"mailcow")
            #local status=$(dockerCheckAppInstalled "webmin" "linux" "check_active")
            #if [ "$status" == "installed" ]; then
                #isError "Virtualmin is installed, this will conflict with $app_name."
                #isError "Installation is now aborting..."
                #dockerUninstallApp "$app_name"
                #return 1
            #elif [ "$status" == "running" ]; then
                #isError "Virtualmin is installed, this will conflict with $app_name."
                #isError "Installation is now aborting..."
                #dockerUninstallApp "$app_name"
                #return 1
            #fi
            #;;
        #"virtualmin")
            #local status=$(dockerCheckAppInstalled "webmin" "linux" "check_active")
            #if [ "$status" == "not_installed" ]; then
              #isError "Virtualmin is not installed or running, it is required."
              #dockerUninstallApp "$app_name"
              #return 1
            #elif [ "$status" == "invalid_flag" ]; then
              #isError "Invalid flag provided..cancelling install..."
              #dockerUninstallApp "$app_name"
              #return 1
            #fi
            #local status=$(dockerCheckAppInstalled "traefik" "docker")
            #if [ "$status" == "not_installed" ]; then
                #while true; do
                    #echo ""
                    #isNotice "Traefik is not installed, it is required."
                    #echo ""
                    #isQuestion "Would you like to install Traefik? (y/n): "
                    #read -p "" virtualmin_traefik_choice
                    #if [[ -n "$virtualmin_traefik_choice" ]]; then
                        #break
                    #fi
                    #isNotice "Please provide a valid input."
                #done
                #if [[ "$virtualmin_traefik_choice" == [yY] ]]; then
                    #dockerInstallApp traefik;
                #fi
                #if [[ "$virtualmin_traefik_choice" == [nN] ]]; then
                    #isError "Installation is now aborting..."
                    #dockerUninstallApp "$app_name"
                    #return 1
                #fi
            #elif [ "$status" == "invalid_flag" ]; then
              #isError "Invalid flag provided..cancelling install..."
              #dockerUninstallApp "$app_name"
              #return 1
            #fi
            #;;
    esac

    isSuccessful "Application is allowed to be installed."
}

dockerCheckAppInstalled() 
{
    local app_name="$1"
    local flag="$2"
    local check_active="$3"
    local package_status=""

    if [ "$flag" = "linux" ]; then
        if dpkg -l | grep -q "$app_name"; then
            package_status="installed"
            if [ "$check_active" = "check_active" ]; then
                if systemctl is-active --quiet "$app_name"; then
                    package_status="running"
                fi
            fi
        else
            package_status="not_installed"
        fi
    elif [ "$flag" = "docker" ]; then
        if [ -f "$docker_dir/$db_file" ]; then
            results=$(sudo sqlite3 "$docker_dir/$db_file" "SELECT name FROM apps WHERE status = 1 AND name = '$app_name';")
        fi 
        if [ -n "$results" ]; then
            package_status="installed"
        else
            package_status="not_installed"
        fi
    else
        package_status="invalid_flag"
    fi

    echo "$package_status"
}
