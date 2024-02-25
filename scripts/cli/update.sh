#!/bin/bash

cliUpdateCommands() 
{
    if [[ "$initial_command1" == "empty" ]]; then 
        initial_command1=""
    fi
    
    if [[ "$initial_command2" == "empty" ]]; then 
        initial_command2=""
    fi
    
    if [[ "$initial_command3" == "empty" ]]; then 
        initial_command3=""
    fi
    
    if [[ "$initial_command4" == "empty" ]]; then 
        initial_command4=""
    fi
    
    if [[ "$initial_command5" == "empty" ]]; then 
        initial_command5=""
    fi

    #echo "initial_command1 $initial_command1"
    #echo "initial_command2 $initial_command2"
    #echo "initial_command3 $initial_command3"
    #echo "initial_command4 $initial_command4"
    #echo "initial_command5 $initial_command5"
}
