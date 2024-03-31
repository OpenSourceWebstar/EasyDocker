#!/bin/bash

tailscaleInstallToContainer()
{
    local app_name="$1"
    local type="$2"

    local result=$(createFolders "loud" $docker_install_user $containers_dir$app_name/tailscale)
    checkSuccess "Creating Tailscale folder"

    copyFile "loud" "${install_scripts_dir}tailscale.sh" "$containers_dir$app_name/tailscale/tailscale.sh" $docker_install_user | sudo tee -a "$logs_dir/$docker_log_file" 2>&1

    if [[ "$type" != "install" ]]; then
        dockerComposeRestart $app_name;
    fi
    #dockerCommandRun "docker cp ${install_scripts_dir}tailscale.sh $app_name:/usr/local/bin/tailscale.sh"
    #checkSuccess "Installing Tailscale installer script into the $app_name container"

    dockerCommandRun "docker exec -it $app_name /usr/local/bin/tailscale.sh"
    checkSuccess "Executing Tailscale installer script in the $app_name container"
}