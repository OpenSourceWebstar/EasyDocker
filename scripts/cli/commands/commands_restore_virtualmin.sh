#!/bin/bash

cliRestoreVirtualminCommands() 
{
    echo ""
    echo "Available Restore Virtualmin Commands:"
    echo ""
    echo "  easydocker restore virtualmin domain [remote|local] [name|all]   - Restore Virtualmin virtual server backups."
    echo "  easydocker restore virtualmin config [remote|local] [name]       - Restore Virtualmin setup config backups."
    echo ""
}
