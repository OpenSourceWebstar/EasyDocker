#!/bin/bash

appMattermostResetUserPassword() 
{
    local mattermostusername
    local mattermostpassword

    while true; do
        isQuestion "Please enter the username or email which you would like to password reset (enter 'x' to exit): "
        read -p "" mattermostusername
        if [[ "$mattermostusername" == [xX] ]]; then
            isNotice "Exiting..."
            endStart;
        fi
        break
    done

    while true; do
        isQuestion "Please enter the password you would like to use (enter 'x' to exit): "
        read -p "" mattermostpassword
        if [[ "$mattermostpassword" == [xX] ]]; then
            isNotice "Exiting..."
            endStart;
        fi
        break
    done

    if [[ "$mattermostusername" != [xX] && "$mattermostpassword" != [xX] ]]; then
        local config_json="$containers_dir/mattermost/volumes/app/mattermost/config/config.json"
        
        # Enable local mode
        result=$(sudo sed -i "s|\"EnableLocalMode\": false|\"EnableLocalMode\": true|" "$config_json")
        checkSuccess "EnableLocalMode set to true for password update."
        dockerRestartAppViaInstall mattermost;
        
        isNotice "Waiting 10 seconds for mattermost to load the local socket"
        sleep 10
        # Update Password
        if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
            dockerCommandRunInstallUser "docker exec mattermost /bin/bash -c \"mmctl --local user change-password $mattermostusername --password $mattermostpassword\" && exit"
        elif [[ $CFG_DOCKER_INSTALL_TYPE == "rooted" ]]; then
            docker exec mattermost /bin/bash -c \"mmctl --local user change-password $mattermostusername --password $mattermostpassword\" && exit
        fi
        # Disable local mode
        result=$(sudo sed -i "s|\"EnableLocalMode\": true|\"EnableLocalMode\": false|" "$config_json")
        checkSuccess "EnableLocalMode set to false for password update."
        dockerRestartAppViaInstall mattermost;

        isSuccessful "Password for username $mattermostusername has been changed to $mattermostpassword if the user exists."
        sleep 5
    fi
}
