#!/bin/bash

cliAppCommands() 
{
    echo ""
    echo "Available App Commands:"
    echo ""
    echo "  easydocker app list [type]             - Display a list of applications"
    echo ""
    echo "  easydocker app install [name]          - Install the specified app"
    echo "  easydocker app start [name]            - Start the specified app (Must be installed)"
    echo "  easydocker app stop [name]             - Stop the specified app (Must be installed)"
    echo "  easydocker app up [name]               - Docker-Compose up (Rebuild app)"
    echo "  easydocker app down [name]             - Docker-Compose up (Uninstall app)"
    echo "  easydocker app backup [name]           - Backup the specified app (Must be installed)"
    echo ""
}
