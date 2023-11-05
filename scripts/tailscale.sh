#!/bin/bash

# This is used ONLY for Docker containers

# Function to detect OS and install packages
install_tailscale() 
{
    local os_info

    if [ -f /etc/os-release ]; then
        source /etc/os-release
        os_info="$ID"
        echo "Operating System: $PRETTY_NAME"
    else
        echo "Unable to determine the OS."
        return
    fi

    case "$os_info" in
        "ubuntu" | "debian")
            echo "Installing packages using apt..."
            apt-get update
            apt-get install -y curl
            ;;
        "centos" | "rhel")
            echo "Installing packages using yum..."
            yum install -y curl
            ;;
        "alpine")
            echo "Installing packages using apk..."
            apk --no-cache add curl
            ;;
        *)
            echo "Unsupported distribution: $os_info"
            ;;
    esac

    # Install Tailscale using its official installation script
    echo "Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh

    echo "Tailscale installed and configured."
}

# Call the function to detect and install
install_tailscale
