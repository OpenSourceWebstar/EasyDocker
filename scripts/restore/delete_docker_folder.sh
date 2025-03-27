#!/bin/bash

restoreDeleteDockerFolder()
{
    local result=$(sudo rm -rf $containers_dir$app_name)
    checkSuccess "Deleting the $app_name Docker install folder in $containers_dir$app_name"
}
