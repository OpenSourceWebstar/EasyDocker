#!/bin/bash

# Used to load any functions after update
startLoad()
{
    checkRequirements;
    dockerSwitcherSwap;
}
