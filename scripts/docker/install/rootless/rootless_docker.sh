#!/bin/bash

installDockerRootless()
{
	if [[ $CFG_DOCKER_INSTALL_TYPE == "rootless" ]]; then
        echo ""
        echo "##########################################"
        echo "###      Install Docker Rootless       ###"
        echo "##########################################"
        echo ""

        #dockerComposeDownAllApps root;
        #dockerServiceStop root;

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Installing System Requirements."
        echo ""

        local docker_install_user_id=$(id -u "$CFG_DOCKER_INSTALL_USER")
        local docker_install_bashrc="/home/$CFG_DOCKER_INSTALL_USER/.bashrc"

        local result=$(sudo apt-get install -y apt-transport-https ca-certificates curl gnupg software-properties-common uidmap dbus-user-session fuse-overlayfs)
        checkSuccess "Installing necessary packages"

        local result=$(sudo systemctl disable --now docker.service docker.socket)
        checkSuccess "Disabling Docker service & Socket"

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Installing slirp4netns."
        echo ""

        # slirp4netns update and install
        if ! command -v slirp4netns &> /dev/null; then
            isNotice "slirp4netns is not installed. Installing..."
            local result=$(sudo apt-get install -y slirp4netns)
            checkSuccess "Installing slirp4netns"
        else
            isNotice "slirp4netns is already installed"
            installed_version=$(slirp4netns --version | awk '{print $2}')
            latest_version=$(curl -s https://api.github.com/repos/rootless-containers/slirp4netns/releases/latest | grep tag_name | cut -d '"' -f 4)
            if [[ "$installed_version" != "$latest_version" ]]; then
                isNotice "slirp4netns version $installed_version is outdated."
                isNotice "Installing version $latest_version..."
                local result=$(sudo apt-get update)
                checkSuccess "Updating apt packages"
                local result=$(sudo apt-get install -y slirp4netns)
                checkSuccess "Installing slirp4netns"
            else
                isSuccessful "slirp4netns version $installed_version is up to date"
            fi
        fi

        if [[ $(lsb_release -rs) == "10" ]]; then
            ((menu_number++))
            echo ""
            echo "---- $menu_number. Updating the sysctl file for Updating Debian 10."
            echo ""
            if sudo grep -q "kernel.unprivileged_userns_clone=1" $sysctl; then
                isNotice "kernel.unprivileged_userns_clone=1 already exists in $sysctl"
            else
                local result=$(echo "kernel.unprivileged_userns_clone=1" | sudo tee -a $sysctl > /dev/null)
                checkSuccess "Adding kernel.unprivileged_userns_clone=1 to $sysctl..."
                local result=$(sudo sysctl --system)
                checkSuccess "Running sudo -u $sudo_user_name sysctl --system..."
            fi
        fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Update the .bashrc file."
        echo ""

        if ! grep -qF "# DOCKER ROOTLESS BASHRC START" "$docker_install_bashrc"; then
            local result=$(echo '# DOCKER ROOTLESS BASHRC START' | sudo tee -a "$docker_install_bashrc" > /dev/null)
            checkSuccess "Adding rootless header to .bashrc"

            local result=$(echo 'export XDG_RUNTIME_DIR=/run/user/${UID}' | sudo tee -a "$docker_install_bashrc" > /dev/null)
            checkSuccess "Adding export path to .bashrc"

            local result=$(echo 'export PATH=/usr/bin:$PATH' | sudo tee -a "$docker_install_bashrc" > /dev/null)
            checkSuccess "Adding export path to .bashrc"

            local result=$(echo 'export DOCKER_HOST=unix:///run/user/${UID}/docker.sock' | sudo tee -a "$docker_install_bashrc" > /dev/null)
            checkSuccess "Adding export DOCKER_HOST path to .bashrc"

            local result=$(echo 'export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID}/bus"' | sudo tee -a "$docker_install_bashrc" > /dev/null)
            checkSuccess "Adding export DBUS_SESSION_BUS_ADDRESS path to .bashrc"

            local result=$(echo '# DOCKER ROOTLESS BASHRC END' | sudo tee -a "$docker_install_bashrc" > /dev/null)
            checkSuccess "Adding rootless header to .bashrc"

            isSuccessful "Added $CFG_DOCKER_INSTALL_USER to bashrc file"
        fi

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up Rootless Docker."
        echo ""

        local result=$(sudo loginctl enable-linger $CFG_DOCKER_INSTALL_USER)
        checkSuccess "Adding automatic start (linger)"

            # Rootless Install
rootless_install=$(cat <<EOF
    curl -fsSL https://get.docker.com/rootless | sh && \
    systemctl --user start docker && \
    systemctl --user enable docker && \
    exit
EOF
)
        local result=$(dockerCommandRunInstallUser "$rootless_install")
        checkSuccess "Setting up Rootless for $CFG_DOCKER_INSTALL_USER"

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up additional Sliprp4netns changes."
        echo ""

        # Sliprp4netns Install
        systemd_user_dir="/home/$CFG_DOCKER_INSTALL_USER/.config/systemd/user"
        local result=$(dockerCommandRunInstallUser "mkdir -p $systemd_user_dir")
        checkSuccess "Create the systemd user directory if it doesn't exist"

        local result=$(dockerCommandRunInstallUser "mkdir -p $systemd_user_dir/docker.service.d")
        checkSuccess "Create the docker.service.d directory if it doesn't exist"

        override_conf_file="$systemd_user_dir/docker.service.d/override.conf"
        local result=$(sudo touch $override_conf_file)
        checkSuccess "Create the override.conf in docker.service.d"	
        
sudo bash -c "cat <<EOL > '$override_conf_file'
[Service]
Environment='DOCKERD_ROOTLESS_ROOTLESSKIT_PORT_DRIVER=slirp4netns'
Environment='DOCKERD_ROOTLESS_ROOTLESSKIT_MTU=$CFG_NETWORK_MTU'
EOL"

        local result=$(sudo chown $CFG_DOCKER_INSTALL_USER:$CFG_DOCKER_INSTALL_USER $override_conf_file)
        checkSuccess "Updating ownership for override.conf"

        local result=$(dockerCommandRunInstallUser "systemctl --user daemon-reload")
        checkSuccess "Reload the systemd user manager configuration"

        isNotice "Restarting docker service...this may take a moment..."
        local result=$(dockerCommandRunInstallUser "systemctl --user restart docker")
        checkSuccess "Reload the systemd user docker service"

        local result=$(sudo cp $sysctl $sysctl.bak)
        checkSuccess "Backing up sysctl file"

        ((menu_number++))
        echo ""
        echo "---- $menu_number. Setting up sysctl file to work with LetsEncrypt."
        echo ""

        # Update sysctl file
        if ! grep -qF "# DOCKER ROOTLESS SYSCTL START" "$sysctl"; then

            local result=$(echo '# DOCKER ROOTLESS SYSCTL START' | sudo tee -a "$sysctl" > /dev/null)
            checkSuccess "Adding rootless header to sysctl"

            local result=$(echo 'net.ipv4.ip_unprivileged_port_start=0' | sudo tee -a "$sysctl" > /dev/null)
            checkSuccess "Adding ip_unprivileged_port_start to sysctl"

            local result=$(echo 'kernel.unprivileged_userns_clone=1' | sudo tee -a "$sysctl" > /dev/null)
            checkSuccess "Adding unprivileged_userns_clone to sysctl"

            local result=$(echo '# DOCKER ROOTLESS SYSCTL END' | sudo tee -a "$sysctl" > /dev/null)
            checkSuccess "Adding rootless end to sysctl"

            isSuccessful "Updated the sysctl with Docker Rootless configuration"
        fi

        local result=$(sudo sysctl --system)
        checkSuccess "Applying changes to sysctl"

        menu_number=0
    fi
}
