#!/bin/bash

dockerPruneNetworks() 
{
    local result=$(dockerCommandRun "docker network prune -f --filter 'name!=vpn'")
    checkSuccess "Pruning unused Docker networks (excluding vpn)"
}
