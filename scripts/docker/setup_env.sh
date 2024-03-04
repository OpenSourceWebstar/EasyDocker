#!/bin/bash

dockerSetupEnvFile()
{
    local result=$(copyFile "loud" $containers_dir$app_name/env.example $containers_dir$app_name/.env $CFG_DOCKER_INSTALL_USER)
    checkSuccess "Setting up .env file to path"
}
