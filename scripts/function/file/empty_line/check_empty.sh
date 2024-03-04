#!/bin/bash

fileHasEmptyLine() 
{
    tail -n 1 "$1" | [[ "$(cat -)" == "" ]]
}
