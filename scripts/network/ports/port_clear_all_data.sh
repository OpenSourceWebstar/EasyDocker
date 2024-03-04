#!/bin/bash

portClearAllData()
{
    # Open Ports
    # Clean previous data (unset openport* variables)
    for varname in $(compgen -A variable | grep -E "^openport[0-9]+"); do
        unset "$varname"
    done
    unset openports open_ports open_initial_ports
    # Used Ports
    # Clean previous data (unset openport* variables)
    for varname in $(compgen -A variable | grep -E "^usedport[0-9]+"); do
        unset "$varname"
    done
    unset usedports used_ports_var used_initial_ports
}
