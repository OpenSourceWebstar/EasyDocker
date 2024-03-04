#!/bin/bash

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
