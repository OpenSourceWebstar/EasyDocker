#!/bin/bash

firewallCommands()
{
    # Allow specific port through the firewall
    if [[ "$firewallallowport" == [yY] ]]; then
        echo ""
        echo "---- Allow specific port through the firewall :"
        echo ""
        while true; do
            isQuestion "Please enter the port you would like to open (enter 'x' to exit): "
            read -p "" firewallallowport_port
            if [[ "$firewallallowport_port" == [xX] ]]; then
                isNotice "Exiting..."
                break
            fi
            if [[ "$firewallallowport_port" =~ ^[0-9]+$ && $firewallallowport_port -ge 1 && $firewallallowport_port -le 65535 ]]; then
                local result=$(sudo ufw allow "$firewallallowport_port")
                checkSuccess "Opening port $firewallallowport_port in the UFW Firewall"
                break
            fi
            isNotice "Please provide a valid port number between 1 and 65535 or enter 'x' to exit."
        done
    fi

    # Block specific port through the firewall
    if [[ "$firewallblockport" == [yY] ]]; then
        echo ""
        echo "---- Block specific port through the firewall :"
        echo ""
        while true; do
            isQuestion "Please enter the port you would like to block (enter 'x' to exit): "
            read -p "" firewallblockport_port
            if [[ "$firewallblockport_port" == [xX] ]]; then
                isNotice "Exiting..."
                break
            fi
            if [[ "$firewallblockport_port" =~ ^[0-9]+$ && $firewallblockport_port -ge 1 && $firewallblockport_port -le 65535 ]]; then
                local result=$(sudo ufw deny "$firewallblockport_port")
                checkSuccess "Blocking port $firewallblockport_port in the UFW Firewall"
                break
            fi
            isNotice "Please provide a valid port number between 1 and 65535 or enter 'x' to exit."
        done
    fi

    # Block port 22 (SSH)
    if [[ "$firewallblock22" == [yY] ]]; then
        echo ""
        echo "---- Block port 22 (SSH) :"
        echo ""
        local result=$(sudo ufw deny 22)
        checkSuccess "Disabling Port 22 through the firewall"
        local result=$(sudo ufw deny ssh)
        checkSuccess "Disabling SSH through the firewall"
    fi

    # Allow port 22 (SSH)
    if [[ "$firewallallow22" == [yY] ]]; then
        echo ""
        echo "---- Allow port 22 (SSH) :"
        echo ""
        local result=$(sudo ufw allow 22)
        checkSuccess "Allowing Port 22 through the firewall"
        local result=$(sudo ufw allow ssh)
        checkSuccess "Allowing SSH through the firewall"
    fi

    # Update logging type for UFW based on Config
    if [[ "$firewallchangelogging" == [yY] ]]; then
        echo ""
        echo "---- Update logging type for UFW based on Config :"
        echo ""
        # Check if CFG_UFW_LOGGING is a valid UFW logging type
        case "$CFG_UFW_LOGGING" in
            on|off|low|medium|high|full)
                # Valid logging type
                local result=$(yes | sudo ufw logging $CFG_UFW_LOGGING)
                checkSuccess "Updating UFW Firewall Logging to $CFG_UFW_LOGGING"
                ;;
            *)
                # Invalid logging type
                isError "Invalid UFW logging type. Please set CFG_UFW_LOGGING to on, off, low, medium, high, or full."
                ;;
        esac
    fi 
}
